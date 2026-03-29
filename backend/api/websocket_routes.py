"""
WebSocket routes para chat con Banny (tutor IA)
Todas las llamadas a OpenAI se hacen desde AQUÍ (backend)
"""

import os
import json
import re
import asyncio
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from datetime import datetime
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

router = APIRouter()

# Almacenar conexiones activas y memoria de chat
connected_clients = {}
chat_histories = {}  # { user_id: [{"role": "user", "content": "..."}, ...] }

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

print(f"[WebSocket] API Key loaded: {'✅' if OPENAI_API_KEY else '❌'}")


@router.websocket("/ws/chat/{user_id}")
async def websocket_chat_endpoint(websocket: WebSocket, user_id: str):
    """
    WebSocket para chat con Banny (IA)
    Flutter se conecta aquí y envía mensajes
    """
    await websocket.accept()
    print(f"✅ WebSocket conectado: {user_id}")
    
    connected_clients[user_id] = websocket
    if user_id not in chat_histories:
        chat_histories[user_id] = []
    
    try:
        from database.session import SessionLocal
        from database.models import SkillTracking
        
        while True:
            # Recibir mensaje del cliente (Flutter)
            data = await websocket.receive_text()
            message = json.loads(data)
            
            msg_type = message.get("type", "message")
            
            # --- Manejo de Eventos de Progreso (Fase 3) ---
            if msg_type == "progress_event":
                event_data = message.get("data", {})
                topic = event_data.get("topic", "general")
                is_correct = event_data.get("is_correct", True)
                time_taken = event_data.get("time_taken", 0)
                
                print(f"📈 Evento de progreso recibido para {user_id}: {topic} - Correcto: {is_correct}")
                
                db = SessionLocal()
                try:
                    stats = db.query(SkillTracking).filter_by(user_id=user_id, topic=topic).first()
                    if not stats:
                        stats = SkillTracking(user_id=user_id, topic=topic)
                        db.add(stats)
                    
                    stats.total_attempts += 1
                    if is_correct:
                        stats.successful_attempts += 1
                    
                    # Actualizar promedio (Moving Average simple)
                    if stats.total_attempts == 1:
                        stats.average_time = time_taken
                    else:
                        stats.average_time = ((stats.average_time * (stats.total_attempts - 1)) + time_taken) / stats.total_attempts
                        
                    stats.accuracy = stats.successful_attempts / stats.total_attempts
                    
                    # Calcular Mastery Score simplificado (0-100)
                    stats.mastery_score = stats.accuracy * 100
                    
                    db.commit()
                except Exception as e:
                    print(f"❌ Error guardando SkillTracking: {e}")
                finally:
                    db.close()
                continue  # No procesar con OpenAI
            
            # --- Procesamiento Normal de Chat ---
            print(f"📨 Mensaje recibido de {user_id}: {message.get('content', '')}")
            
            # Procesar mensaje con OpenAI
            response = await process_chat_message(message, user_id)
            
            # Enviar respuesta a Flutter
            await websocket.send_json(response)
            
    except WebSocketDisconnect:
        print(f"❌ WebSocket desconectado: {user_id}")
        connected_clients.pop(user_id, None)
        # Opcional: limpiar historial al desconectar para no guardar estado eterno
        # chat_histories.pop(user_id, None) 
    
    except Exception as e:
        print(f"❌ Error en WebSocket: {e}")
        try:
            await websocket.close()
        except:
            pass


def _extract_and_normalize_equation(text: str) -> dict | None:
    """Extrae y normaliza ecuaciones matemáticas simples desde el texto del usuario"""
    # Eliminar espacios para hacer regex más fácil
    clean_text = text.strip().replace(' ', '')
    
    # Normalizar: superscripts unicode -> ^ notation, y unicode minus/math symbols
    clean_text = (clean_text
        .replace('\u2212', '-')
        .replace('\u2013', '-')
        .replace('²', '^2')
        .replace('³', '^3')
        .replace('\u00D7', '*')
        .replace('\u00F7', '/')
    )
    
    # Patrones por tipo de ecuación
    patterns = {
        'cubic':         r'^[+-]?\d*[a-zA-Z]\^3[+-]?\d*=',
        'quadratic':     r'^[+-]?\d*[a-zA-Z]\^2[+-]?\d*=',
        'factorization': r'^[+-]?\d*[a-zA-Z]\^2[+-]\d+[a-zA-Z]=0$',
        'distributive':  r'^\d+\([a-zA-Z][+-]\d+\)=',
        'linear':        r'^[+-]?\d*[a-zA-Z][+-]?\d*=',
    }
    
    for topic, pattern in patterns.items():
        if re.search(pattern, clean_text, re.IGNORECASE):
            return {'equation': clean_text, 'topic': topic}
            
    return None


async def process_chat_message(message: dict, user_id: str) -> dict:
    """
    Procesa mensajes de chat usando OpenAI y mantiene ventana de contexto.
    """
    
    if not OPENAI_API_KEY:
        print("❌ OPENAI_API_KEY no configurada en .env")
        return {
            "type": "error",
            "content": "Error: OpenAI API key not configured",
            "timestamp": datetime.now().isoformat(),
            "sender": "banny"
        }
    
    try:
        from openai import AsyncOpenAI
        from database.session import SessionLocal
        from database.models import UserProfile
        
        # Obtener contexto (template y exercise_type) si viene de Flutter
        context_data = message.get("context", {})
        template_mode = context_data.get("template", "guiado")
        exercise_type = context_data.get("exercise_type") # ⭐ NUEVO (Fase 3/4)
        
        # Obtener perfil de usuario
        db = SessionLocal()
        try:
            profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
            if profile:
                tone = profile.preferred_tone or "amigable"
                # ✅ Override Scaffolding basado en el Template Dinámico (Fase 3)
                if template_mode == "guiado":
                    scaffolding = "alto (explicar paso a paso, guiar detalladamente)"
                elif template_mode == "libre":
                    scaffolding = "medio (dar pistas solo si se traba)"
                elif template_mode == "desafio":
                    scaffolding = "mínimo (no dar pistas directas, solo hacer preguntas muy sutiles o alentar)"
                else:
                    scaffolding = profile.scaffolding_level or "medio (dar pistas solo si se traba)"
                    
                objective = profile.learning_objective or "entender paso a paso"
                interests_list = profile.specific_interests or []
                interests = ", ".join(interests_list) if interests_list else "Ninguno"
            else:
                tone = "amigable"
                scaffolding = "medio (dar pistas solo si se traba)"
                objective = "entender paso a paso"
                interests = "Ninguno"
        finally:
            db.close()
            
        # Crear cliente OpenAI con la API key del backend
        client = AsyncOpenAI(api_key=OPENAI_API_KEY)
        
        user_message = message.get("content", "")
        
        # Construir prompt del sistema dinámico basado en contexto y perfil
        system_prompt = f"""Eres Banny, un tutor de matemáticas altamente interactivo. 
Tu Tono y Personalidad: {tone}.
El Objetivo del alumno es: {objective}.
Modo de sesión actual: {template_mode.upper()}
Regla de Ayuda (Scaffolding): {scaffolding}.
Intereses del alumno: {interests}.

Tu objetivo principal es ayudar a resolver problemas matemáticos usando el MÉTODO SOCRÁTICO.

REGLAS PEDAGÓGICAS CRÍTICAS:
1. NUNCA des la respuesta directa. Haz preguntas guía.
2. Usa la METÁFORA DE LA BALANZA (lados, equilibrio, pesos).
"""

        # ⭐ LÓGICA DE GENERACIÓN DE EJERCICIOS DINÁMICOS (SKELETONS)
        if exercise_type:
            system_prompt += f"""
EL USUARIO HA SOLICITADO UN EJERCICIO DE TIPO: {exercise_type.upper()}.
Debes generar un JSON que represente este ejercicio específico con creatividad acorde al tipo (ej. magia para 'destructor_ecuaciones', dulces para 'candymath', ninjas para 'academia_ninja', etc).

FORMATO DE RESPUESTA PARA EJERCICIOS:
Si el tipo solicitado es un juego (tap_destroy, fill_blank, multiple_choice, destructor_ecuaciones, beatmath, destruir_seleccion, candymath, academia_ninja, dardos), usa ESTRICTAMENTE la siguiente estructura:

{{
  "exercise_type": "{exercise_type}",
  "equation": "La ecuación a resolver o texto del problema",
  "story_context": "Breve frase temática del juego (ej. ¡Prepara tus dardos! o ¡Corta las ecuaciones!)",
  "instruction": "Instrucción de lo que debe hacer en el juego",
  "pieces": ["Elemento falso 1", "Elemento falso 2", "Opción o respuesta correcta"],
  "correct_answer": "La opción exacta de la lista que es correcta"
}}

Si el tipo es "drag_drop" o no aplica, usa el formato estándar de conversación:
{{
  "text": "Mensaje socrático de Banny",
  "ui_action": "set_equation",
  "ui_value": "3x + 2 = 11"
}}
"""
        else:
            system_prompt += """
Siempre debes responder en formato JSON con esta estructura:
{
  "text": "Tu mensaje para el estudiante",
  "ui_action": "none" | "set_equation" | "highlight" | "apply_operation",
  "ui_value": "Valor asociado"
}
"""

        if context_data:
            current_eq = context_data.get("current_equation", "Ninguno")
            actions = context_data.get("recent_actions", [])
            actions_text = ", ".join(actions) if actions else "Ninguna"
            
            error_action = context_data.get("recent_invalid_action")
            error_text = f"\\u00daLTimo error cometido por el usuario: {error_action}\\nEl usuario está atascado o ha fallado consecutivamente." if error_action else ""
            
            system_prompt += f"""\n\n[CONTEXTO MATEMÁTICO OCULTO ENVIADO POR LA INTERFAZ]
Estado actual de la ecuación en pantalla: {current_eq}
Últimas acciones del usuario en pantalla: {actions_text}
{error_text}

Usa este contexto reportado por el entorno gráfico para entender exactamente en qué punto de la resolución está el usuario y guiarlo."""

        # --- Manejo de Historial (Context Window) ---
        history = chat_histories.get(user_id, [])
        history.append({"role": "user", "content": user_message})
        
        # Límite estricto de 6 mensajes (los últimos 3 pares pregunta-respuesta)
        if len(history) > 6:
            history = history[-6:]
            chat_histories[user_id] = history
            
        messages_to_send = [{"role": "system", "content": system_prompt}] + history

        # Llamar a OpenAI
        response = await asyncio.wait_for(
            client.chat.completions.create(
                model="gpt-4o-mini",
                response_format={ "type": "json_object" },
                messages=messages_to_send,
                temperature=0.7,
                max_tokens=300
            ),
            timeout=10.0
        )
        
        ai_response = response.choices[0].message.content
        
        # Parseamos el JSON para guardarlo correctamente en el historial
        try:
            parsed_json = json.loads(ai_response)
            clean_text = parsed_json.get("text", ai_response)
        except:
            clean_text = ai_response
            
        history.append({"role": "assistant", "content": clean_text})

        # EXTRAER ECUACIÓN (Fase 3: disparar ejercicios desde el chat)
        parsed_eq = _extract_and_normalize_equation(user_message)
        
        response_dict = {
            "type": "message",
            "content": ai_response,
            "timestamp": datetime.now().isoformat(),
            "sender": "banny",
            "model_used": "gpt-4o-mini",
            "source": "openai"
        }
        
        if parsed_eq:
            response_dict["equation"] = parsed_eq["equation"]
            response_dict["topic"] = parsed_eq["topic"]
            response_dict["launch_exercise"] = True
            
        return response_dict
        
    except asyncio.TimeoutError:
        print("❌ OpenAI timeout (>10s)")
        return {
            "type": "error",
            "content": "⏱️ Banny tardó mucho en responder. Intenta de nuevo.",
            "timestamp": datetime.now().isoformat(),
            "sender": "banny"
        }
    
    except ImportError as e:
        print(f"❌ openai package import error: {e}")
        return {
            "type": "error",
            "content": f"Error: openai package not installed - {e}",
            "timestamp": datetime.now().isoformat(),
            "sender": "banny"
        }
    
    except Exception as e:
        print(f"❌ OpenAI Exception ({type(e).__name__}): {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            "type": "error",
            "content": f"Error de Banny: {str(e)}",
            "timestamp": datetime.now().isoformat(),
            "sender": "banny"
        }
