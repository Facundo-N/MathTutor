# 🛠️ Manual Técnico Definitivo: MathTutor (Banny AI)

**ATENCIÓN IA:** Este documento es la fuente **ÚNICA Y DEFINITIVA** de verdad para la arquitectura, el contexto, la filosofía de diseño y la estructura técnica de este proyecto. Léelo y consúltalo siempre antes de realizar modificaciones arquitectónicas o debugear problemas de integración.

---

## 1. Visión y Filosofía Arquitectónica ("The Living Board")

MathTutor no es un chatbot acoplado a una calculadora. Es un **Sistema de Tutoría Inteligente (ITS)** adaptativo. La filosofía central se basa en:

1.  **Separación de Responsabilidades Pedagógicas (Triada Híbrida):**
    *   **Capa UI (Flutter):** Maneja las "físicas" matemáticas. Las ecuaciones no son texto, son un árbol de *DraggableMathPieces*. El signo `=` actúa como un "Portal" y una balanza visual.
    *   **Capa Lógica (Backend - Python/SymPy):** Motor matemático determinista (coste $0 y 100% exactitud). Genera las ecuaciones, resuelve, y valida la legalidad de los movimientos.
    *   **Capa Narrativa/Tutor (Backend - OpenAI GPT-4o-mini):** El "Alma" (Banny). Provee el enrutamiento pedagógico, el *scaffolding* (nivel de ayuda), y adapta la historia en base al "Mastery Score" y los intereses del usuario.

2.  **Mecánicas Visuales Intuitivas:**
    *   Cruzar el `=` invierte la operación (se debe sentir físicamente, la balanza acusa recibo del desequilibrio).
    *   Fraccionar números (Splitting) mediante gestos de "zoom out / pellizco".
    *   Cancelar términos opuestos mediante gestos de corte ("Slash").

---

## 2. Diagrama del Sistema y Estructura de Directorios

### 📱 Frontend (Flutter en `lib/`)
Aplicación orientada a componentes y flujo de estado local, diseñada para dispositivos móviles (portrait).

*   `main.dart`: Entry point, inyector de dependencias globales y enrutador.
*   `providers/`: Gestión de estado de la sesión (Riverpod/Provider). Contiene `UserProfile`, progreso local e inyectores de servicios.
*   `services/`:
    *   `banny_chat_service.dart`: Administra el WebSocket bidireccional, el ciclo de vida de conexión y la recolección de eventos para enviar al backend.
    *   `math_engine_service.dart`: Puente local de lógica matemática o validaciones primarias antes de disparar peticiones.
*   `screens/`: Pantallas de estado completo.
    *   `banny_chat_screen.dart` / `unified_board_chat_screen.dart`: UI Principal vertical que integra el canvas en el 80% (pizarra) y el chat como pop-up overlay o panel inferior.
    *   `new_home_screen.dart` / `modern_dashboard_screen.dart`: Dashboard de selección de ejercicios.
*   `widgets/`: Componentes.
    *   E.g., `interactive_problem_card.dart`, `DraggableMathPiece`, modales interactivos.
*   `models/`: Estructuras de datos puras (Data Classes).
*   `utils/`: Helpers, tokens de diseño y configuraciones temáticas (visual_styles).

### 🐍 Backend (FastAPI Python en `backend/`)
Servidor asíncrono que orquesta inteligencia, bases de datos y la librería simbólica.

*   `main.py`: Arranque de ASGI (Uvicorn), configuración CORS global y definición de la app contenedora.
*   `api/` & `routes/`:
    *   `websocket_routes.py`: Punto crítico de entrada para la comunicación con latencia mínima. Inyecta prompts de sistema y canaliza JSONs de eventos UI.
    *   `profile_routes.py`: Endpoints RESTful estáticos (Guardar progresos, configuración de usuario).
*   `ai/`:
    *   `problem_generator_ai.py`: Wrappers para las llamadas a la API de validación pedagógica OpenAI. Emplea GPT-4o-mini.
*   `math_engine/`:
    *   `solver.py`: Scripts core utilizando `sympy` para manipulación de árboles abstractos de sintaxis matemáticos (AST), encontrar dependencias y escupir validaciones binarias legales.
*   `database/` & `models/`: Modelos ORM (SQLAlchemy u otros) e inicialización de SQLite (local)/PostgreSQL.
    *   Base principal `math_tutor.db`. Abarca métricas (`SkillTracking`), progreso, scores, perfil, metadata de onboarding.

---

## 3. Protocolo de Comunicación Cliente-Servidor

### Conexión WebSocket (El Cordón Umbilical)
El laboratorio de Flutter emite eventos JSON y el backend responde. Existe un estricto control de memoria/ventana temporal de contexto.

**Ejemplo de Payload desde Flutter (Evento de Frustración):**
```json
{
  "type": "math_action",
  "user_id": "uuid-v4-abc",
  "ejercicio_id": "ecuaciones_lvl_1",
  "estado_inicial": "2x + 5 = 11",
  "estado_actual": "2x = 11 + 5",
  "tiempo_transcurrido": 45,
  "consecutivos_invalidos": 3,
  "ultimo_error": {
     "tipo": "desequilibrio_por_signo",
     "accion": "Movió bloque +5 al lado derecho sin invertir signo."
  }
}
```

El servidor intercepta este payload, valida en `math_engine`, solicita generación de `hint` vía `ai` usando el Scaffolding del usuario, y retorna un JSON con un mensaje de chat interactivo al tutor.

### Manejo de IP y Contexto en Emuladores
- **El Laberinto Android:** El emulador asigna la IP `10.0.2.2` al host. `127.0.0.1` apunta a la propia sandbox del emulador.
- `banny_chat_service.dart` posee lógica discriminadora de `Platform.isAndroid` para definir la URL Base.
- USB Debugging físico exige correr previamente: `adb reverse tcp:8000 tcp:8000`.

---

## 4. Perfil Táctico de Personalización

La IA adapta dinámicamente el *System Prompt* en la capa `websocket_routes.py` basado en el `UserProfile` persistido. Los cuatro vectores direccionales (Ejes) son:

1.  **Dificultad (Mastery Score):** Subida o bajada dinámica. Reglas: 3 aciertos suben nivel, 2 fallos cambian la aproximación.
2.  **Andamiaje (Scaffolding):**
    *   Alto: Explicaciones directas paso a paso.
    *   Bajo: Inquisitivo, deja intentar y fallar sin interrumpir.
3.  **Tono:** (e.g. Socrático, Directo, Motivador, Minimalista).
4.  **Contexto/Intereses:** Base estocástica para "flavor text" en los problemas, evitando *Roleplay* excesivo o infantil y priorizando realismo narrativo (e.g. usar "Drones" o "Música" como entidades enumerables en problemas matemáticos).

---

## 5. Decisiones de Despliegue y Seguridad Conocidas

- **Cost-Efficiency:** Capa $0$ SymPy asegura legalidad. Capa de modelos menores de IA (GPT-4o-mini) para parsing lingüístico. Ventana de contexto deslizante estricta (máximo 6 interacciones recordadas activamente).
- **Gestión de Secretos:** `OPENAI_API_KEY` siempre resguardada en `backend/.env`. Flutter JAMÁS negocia llaves directamente.
- **Trazabilidad:** Los errores persisten logueados principalmente en `backend/server.log` y dependencias de test locales (como `test_websocket.py`).
