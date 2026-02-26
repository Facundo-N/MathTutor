"""
WebSocket routes para chat con Banny (tutor IA)
Todas las llamadas a OpenAI se hacen desde AQUÍ (backend)
"""

import os
import json
import asyncio
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from datetime import datetime
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

router = APIRouter()

# Almacenar conexiones activas
connected_clients = {}

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
    
    try:
        while True:
            # Recibir mensaje del cliente (Flutter)
            data = await websocket.receive_text()
            message = json.loads(data)
            
            print(f"📨 Mensaje recibido de {user_id}: {message.get('content', '')}")
            
            # Procesar mensaje con OpenAI
            response = await process_chat_message(message, user_id)
            
            # Enviar respuesta a Flutter
            await websocket.send_json(response)
            
    except WebSocketDisconnect:
        print(f"❌ WebSocket desconectado: {user_id}")
        connected_clients.pop(user_id, None)
    
    except Exception as e:
        print(f"❌ Error en WebSocket: {e}")
        try:
            await websocket.close()
        except:
            pass


async def process_chat_message(message: dict, user_id: str) -> dict:
    """
    Procesa mensajes de chat usando OpenAI
    LA API KEY ESTÁ AQUÍ, EN EL BACKEND (SEGURO)
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
        print(f"🔍 Iniciando OpenAI para mensaje: {message.get('content', '')[:30]}...")
        print(f"📌 API Key exists: {bool(OPENAI_API_KEY)}")
        print(f"📌 API Key length: {len(OPENAI_API_KEY)}")
        
        from openai import AsyncOpenAI
        
        # Crear cliente OpenAI con la API key del backend
        client = AsyncOpenAI(api_key=OPENAI_API_KEY)
        print("✅ AsyncOpenAI cliente creado")
        
        user_message = message.get("content", "")
        print(f"📨 Enviando a OpenAI: {user_message[:50]}...")
        
        # Construir prompt del sistema dinámico basado en contexto
        system_prompt = """Eres Banny, un tutor amigable y paciente de matemáticas. 
Tu objetivo es ayudar a estudiantes a resolver problemas matemáticos paso a paso usando estrictamente el MÉTODO SOCRÁTICO y ANDAMIAJE (Scaffolding).

REGLAS PEDAGÓGICAS CRÍTICAS:
1. NUNCA des la respuesta directa ni dictes el siguiente paso explícito (Ejemplo de lo que NO debes hacer: "Comencemos restando 2 de ambos lados").
2. Haz preguntas guía para que el estudiante deduzca por sí mismo qué hacer (Ejemplo CORRECTO: "Si queremos dejar a la 'x' sola en este lado, ¿qué bloque nos está molestando? ¿Cómo podríamos quitarlo para mantener la balanza equilibrada?").
3. Mantén siempre la METÁFORA VISUAL DE LA BALANZA. Habla de "lados de la balanza", "bloques", "peso" y "mantener el equilibrio".

Siempre debes responder en formato JSON estricto con esta estructura exacta:
{
  "text": "Tu mensaje hablado/escrito para el estudiante de máximo 3 líneas",
  "ui_action": "none" | "set_equation" | "highlight" | "apply_operation",
  "ui_value": "Valor asociado a la acción"
}

- "ui_action" debe ser "none" si solo estás hablando.
- Usa "set_equation" para poner una ecuación en pantalla para explicar (ej: ui_value: "3x + 2 = 11").
- Usa "apply_operation" IMPORTANTE: Sí debes usar esta función frecuentemente para mostrar la regla de oro: mantener la igualdad en ambos lados. Si el estudiante dice "pasemos el 3 al otro lado", usa ui_action "apply_operation" con ui_value "-3" para añadir visualmente -3 en ambos lados de la balanza.
- Cuando haya una suma o resta matemática obvia pendiente (ej. si agregaste -3 a ambos lados), pregúntale al alumno: "¿Cuál es el resultado de esta operación?" y espera a que te responda por chat o lo resuelva en los bloques. No le des el resultado de la suma inmediatamente.
- Sigue siendo Socrático, pero APOYATE FUERTEMENTE en `apply_operation` para enseñar visualmente la igualdad."""

        context_data = message.get("context")
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

Usa este contexto reportado por el entorno gráfico para entender exactamente en qué punto de la resolución está el usuario y guiarlo, corregirlo, o manipular la ecuación (usando ui_action) según sea necesario. Recuerda usar el método Socrático y referenciar lo que el usuario acaba de intentar hacer mal en la pantalla."""

        print(f"🧠 Contexto inyectado: {bool(context_data)}")

        # Llamar a OpenAI
        print("⏳ Esperando respuesta de OpenAI en formato JSON...")
        response = await asyncio.wait_for(
            client.chat.completions.create(
                model="gpt-4o-mini",
                response_format={ "type": "json_object" },
                messages=[
                    {
                        "role": "system",
                        "content": system_prompt
                    },
                    {
                        "role": "user",
                        "content": user_message
                    }
                ],
                temperature=0.7,
                max_tokens=300
            ),
            timeout=10.0
        )
        
        ai_response = response.choices[0].message.content
        print(f"✅ OpenAI respondió exitosamente (JSON): {ai_response[:50]}...")
        
        return {
            "type": "message",
            "content": ai_response,
            "timestamp": datetime.now().isoformat(),
            "sender": "banny",
            "model_used": "gpt-4o-mini",
            "source": "openai"
        }
        
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
