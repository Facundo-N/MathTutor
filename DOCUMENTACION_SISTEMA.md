# 📖 Documentación Técnica: MathTutor (Proyecto Banny AI)

Esta guía proporciona una visión técnica detallada del ecosistema de MathTutor, diseñada para desarrolladores y educadores interesados en la arquitectura de aprendizaje adaptativo.

---

## 🏗️ Arquitectura General

El sistema se basa en una arquitectura **Cliente-Servidor** con comunicación bidireccional en tiempo real:

1.  **Frontend (App Móvil)**: Desarrollada en Flutter, actúa como la interfaz de manipulativos matemáticos y el cliente de chat.
2.  **Backend (Servidor API)**: Desarrollado en FastAPI (Python), actúa como el "Cerebro", gestionando la lógica de IA, la persistencia de datos y el motor matemático.
3.  **Comunicación**: 
    *   **REST API**: Para operaciones de perfil, carga de datos y verificaciones.
    *   **WebSockets**: Para la interacción de baja latencia con el tutor Banny (streaming de IA).

---

## 📱 Frontend (Carpeta `lib/`)

### 1. Núcleo y Estado (`providers/`)
*   **`UserProvider`**: Gestiona el perfil del usuario, la identidad (UUID) y las preferencias de aprendizaje (Tono, Scaffolding, Contexto).
*   **`BoardProvider`**: Controla el estado del laboratorio matemático, guardando el historial de pasos realizados en una ecuación.
*   **`VisualStyleProvider`**: Gestiona la estética de la app (Modo Dark/Light, templates de diseño).

### 2. Componentes Visuales (`widgets/`)
*   **`EquationLabWidget`**: El componente más complejo. Un canvas interactivo que permite "romper", "unir" y operar términos de una ecuación mediante gestos.
*   **`AICoachPopup`**: Ventana flotante que contiene a Banny. Se conecta mediante WebSockets para dar feedback inmediato sin interrumpir la resolución.
*   **`MathExpressionDisplay`**: Renderizado dinámico de fórmulas matemáticas utilizando CustomPainters para una estética premium.

### 3. Servicios (`services/`)
*   **`BannyChatService`**: El puente WebSocket. Maneja la reconexión automática y el envío de contexto (pasos de la ecuación) a la IA.
*   **`MathApiService`**: Encargado de las llamadas al motor de resolución para verificar si un paso matemático es válido.
*   **`TtsService`**: (Opcional) Gestiona la síntesis de voz para que Banny pueda "hablar" al estudiante.

---

## 🐍 Backend (Carpeta `backend/`)

### 1. Rutas de API (`api/`)
*   **`profile_routes.py`**: Endpoints para crear y actualizar el perfil del usuario. Sincronizado con PostgreSQL/SQLite.
*   **`websocket_routes.py`**: El canal crítico. Aquí se procesa el lenguaje natural del alumno y se inyecta el "System Prompt" personalizado.

### 2. Inteligencia Artificial (`ai/`)
*   **`problem_generator_ai.py`**: Utiliza GPT-4o-mini para crear narrativas de problemas basadas en los intereses del usuario (ej: si le gusta el espacio, los problemas de álgebra tendrán temática espacial).

### 3. Motor Matemático (`math_engine/`)
*   **`solver.py`**: Utiliza la librería **SymPy** para resolver y validar ecuaciones paso a paso. No solo da el resultado, valida la lógica de cada transición.

---

## ⚙️ Configuración y Despliegue

### Requisitos del Backend
*   **Python**: 3.10+
*   **Variables de Entorno (`.env`)**:
    *   `OPENAI_API_KEY`: Requerida para la IA.
    *   `DATABASE_URL`: URL de conexión a la base de datos (PostgreSQL recomendada).

### Conectividad Móvil
Para que la app en un dispositivo real se conecte al servidor local:
1.  Asegurarse de que ambos estén en la misma red Wi-Fi.
2.  Configurar la IP en `MathApiService` y `BannyChatService` (ej: `192.168.x.x`).
3.  Si usas USB, ejecutar: `adb reverse tcp:8000 tcp:8000`.

---

## 🛠️ Mantenimiento y Debugging

*   **Logs del Servidor**: Ubicados en `backend/server.log`. Muestran cada petición y error de IA.
*   **Modo Debug de Flutter**: Los servicios imprimen `✅ WebSocket conectado` o `❌ Error de conexión` en la consola para facilitar el rastreo.

---

*Última actualización: Marzo 2026 - Fase 4 (Estabilización)*
