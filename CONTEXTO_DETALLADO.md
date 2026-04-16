# 📚 Contexto Detallado del Proyecto: MathTutor (Banny AI)

## 🌟 La Visión del Proyecto
MathTutor es un ecosistema pedagógico de vanguardia. Su misión es transformar la ansiedad matemática en confianza a través de **Banny**, un tutor inteligente (IA) que aplica el método socrático. No solo resuelve problemas; enseña a pensar mediante la visualización interactiva y la personalización extrema.

---

## 🏗️ Estructura del Ecosistema

El proyecto se divide en dos grandes mundos sincronizados:

### 1. El Frontend (Flutter) - `lib/`
Diseñado para la máxima fluidez visual y una experiencia de usuario "Premium".

#### `main.dart` — Punto de Entrada
*   Usa **Provider** (`MultiProvider`) con 4 providers globales: `VisualStyleProvider`, `AdaptiveStyleProvider`, `BoardProvider`, `UserProvider`.
*   Fuerza orientación **portrait-only** (`DeviceOrientation.portraitUp`).
*   Tema: Material 3 con `seedColor: #6B5CE7` (violeta), fuente Poppins.
*   **6 rutas estáticas**: `/` (presentación), `/style-onboarding`, `/onboarding-survey`, `/home` (dashboard), `/chat`, `/equation_lab`.
*   **1 ruta dinámica**: `/board` con parámetros `equation` y `template` (`guiado`, `libre`, `desafio`).

#### `screens/` — Pantallas Principales (6 archivos)
| Archivo | Peso | Descripción |
|---------|------|-------------|
| `presentation_slide.dart` | 12.7 KB | Slides de presentación inicial del producto. Pantalla de bienvenida. |
| `style_onboarding_screen.dart` | 10.8 KB | Onboarding para detectar preferencias visuales del alumno (playful/balanced/minimal). |
| `onboarding_survey_screen.dart` | 13.5 KB | Encuesta profunda de personalización: tono, scaffolding, intereses, objetivos, nivel de dificultad. |
| `modern_dashboard_screen.dart` | 48.7 KB | **Cerebro central**. Permite entrada manual de ecuaciones, selección de modos de sesión, acceso a todas las plantillas y limpieza de proyectos hardcodeados. |
| `banny_chat_screen.dart` | 2.1 KB | Pantalla de chat standalone con Banny. |
| `unified_board_chat_screen.dart` | 4.3 KB | Integra el tablero matemático + chat de Banny en una sola vista. Recibe `equation` y `template`. |
| `tutorial_screen.dart` | 33.5 KB | **Tutorial Pedagógico Evolutivo**. Implementa un flujo de 3 pasos: 1. Abstracción (fórmulas), 2. Ejemplo Guiado (números generados dinámicamente) y 3. Práctica. Incluye **Lip-Sync** sincronizado con TTS. |
| `destructor_preview_screen.dart` | 5.3 KB | Previsualización de la mecánica del destructor de ecuaciones con selección múltiple. |

#### `models/` — Modelos de Datos (16 archivos)
| Modelo | Descripción |
|--------|-------------|
| `ai_exercise_model.dart` | Estructura de ejercicios generados por la IA (tipo, ecuación, piezas, respuesta correcta). |
| `board_state.dart` (5.7 KB) | Estado completo del tablero interactivo (piezas, posiciones, historial). |
| `chat_message_model.dart` | Modelo de mensaje de chat para la comunicación con Banny. |
| `class_model.dart` | Modelo de datos para las clases/materias. |
| `equation_state.dart` | Estado de la ecuación actual (lado izquierdo, derecho, operación pendiente). |
| `math_element.dart` (5 KB) | Elemento matemático con tipo (número, variable, operador), valor, y metadata visual. |
| `math_node.dart` | Nodo en el árbol de expresiones matemáticas. |
| `math_piece.dart` | Pieza visual arrastrable del tablero (extensión de MathElement con posición y animaciones). |
| `math_problem.dart` | Problema matemático completo (expresión, tema, dificultad). |
| `math_solution.dart` | Solución con pasos intermedios, hints y datos de gráfico. |
| `session_types.dart` | Tipos de sesión: `exploración`, `desafío`, `libre`. |
| `tutor_action.dart` | Acciones del tutor IA: `set_equation`, `highlight`, `apply_operation`, `none`. |
| `user_behavior.dart` (2.1 KB) | Comportamiento del usuario: velocidad, precisión, uso de pistas, método de input. |
| `user_profile.dart` (3 KB) | Perfil completo del usuario con preferencias, estilo detectado, intereses. |
| `user_signal.dart` | Señal de comportamiento capturada en tiempo real (tipo, timestamp, metadata). |
| `visual_style.dart` (7.6 KB) | Definición extensa de estilos visuales (colores, tipografías, animaciones) por modo. |

#### `providers/` — Gestión de Estado (6 archivos)
| Provider | Descripción |
|----------|-------------|
| `user_provider.dart` | Maneja identidad (UUID persistente vía `SharedPreferences`), sesión y perfil. |
| `adaptive_style_provider.dart` (10 KB) | Ajusta la interfaz dinámicamente según la personalidad detectada del alumno. |
| `board_provider.dart` (12.3 KB) | Estado del tablero: piezas, ecuación activa, historial de movimientos, validación. |
| `equation_provider.dart` | Estado de la ecuación en resolución (parsing, validación de pasos). |
| `visual_style_provider.dart` | Proveedor de estilos visuales dinámicos (temas, colores, fuentes). |
| `sesion_matematica_controller.dart` | Controlador de sesión: temporizador, contadores de progreso, modo actual. |

#### `services/` — Servicios del Frontend (13 archivos)
| Servicio | Peso | Descripción |
|----------|------|-------------|
| `answer_validator.dart` | 9.8 KB | **Validador inteligente** multi-formato: enteros, decimales, fracciones, porcentajes, ecuaciones (`x=2`), texto (`sí/no`). Incluye tolerancia para decimales (ε=0.01) y detección de "cercanía". |
| `cognitive_state_manager.dart` | 10 KB | **Máquina de estados cognitivos** (Exploración → Construcción → Fluidez). Reglas de transición basadas en errores consecutivos, tasa de aciertos, señales de confusión. Cada estado configura: intensidad visual, detalle de pasos, tono, frecuencia de ánimo. |
| `banny_chat_service.dart` | 3.6 KB | Cliente WebSocket para comunicación en tiempo real con el backend. |
| `hyperpersonalized_tutor_service.dart` | 4.2 KB | Servicio de hiperpersonalización que consulta el perfil del alumno al backend. |
| `math_api_service.dart` | 6.4 KB | Cliente HTTP para la API REST del backend (`/api/solve`, `/api/hints`, `/api/problem/generate/adaptive`). |
| `math_engine_service.dart` | 8.1 KB | Motor de parsing y resolución local (frontend-side) para validación rápida sin backend. |
| `math_parser.dart` | 12.7 KB | Parser completo de expresiones matemáticas: tokenización, construcción de árbol, soporte para multiplicación implícita, exponentes, paréntesis. |
| `signal_collector.dart` | 8.3 KB | Recolector de señales de comportamiento del usuario (taps, tiempos, errores, métodos de input). |
| `signal_service.dart` | 2.4 KB | Envío batch de señales al backend (`/api/signals/ingest`). |
| `tts_service.dart` | 4.2 KB | Servicio Text-to-Speech: integra Kokoro TTS local (backend) con `just_audio` para reproducir audio WAV. |
| `profile_service.dart` | 1.4 KB | Cliente HTTP para guardar/cargar perfil del usuario (onboarding). |
| `openai_config.dart` | 0.7 KB | Configuración de la API key de OpenAI (solo referencia, la key real está en el backend). |
| `visual_style_provider.dart` (services/) | 5.9 KB | Proveedor de estilos visuales con lógica de detección automática. |

#### `widgets/` — Widgets e Interactividad (23+ archivos)

**Widgets Core:**
| Widget | Peso | Descripción |
|--------|------|-------------|
| `equation_lab.dart` | **108 KB** | **CENTRO DE APRENDIZAJE**. Sandbox interactivo donde los términos son piezas físicas arrastrables. Orquestador de flujos (Tutorial → Carga → Juego) con soporte para contexto visual de bloques. |
| `learning_flow_orchestrator.dart` | 8.6 KB | **Coordinador de Fases**. Gestiona la transición entre el tutorial, la pantalla de carga y el mini-juego final. |
| `topic_loading_screen.dart` | 6.5 KB | Pantalla de transición con barra de progreso animada, íconos de tema (x², x³) y mensajes personalizados. |
| `animated_bunny.dart` | 7.2 KB | **Banny Rebuilt**. Personaje construido con capas SVG independientes (orejas, cabeza, torso, accesorios) para animaciones expresivas. Incluye corrección de ojos y saludo de brazo. |
| `animated_math_board.dart` | 15.9 KB | Tablero matemático con animaciones procedurales. |
| `chat_widget.dart` | 13.4 KB | Widget de chat integrado con Banny (mensajes, input, scroll automático). |
| `equation_graph_widget.dart` | 13.7 KB | Gráfico interactivo de ecuaciones usando `fl_chart`. Muestra funciones con punto de solución marcado. |
| `ai_coach_popup.dart` | 14.6 KB | Popup de coaching de Banny con animaciones y mensajes contextuales. |
| `interactive_board_widget.dart` | 12.6 KB | Tablero interactivo con zonas de drop y validación de movimientos. |
| `math_solution_widget.dart` | 11.3 KB | Visualización paso a paso de la solución con LaTeX (flutter_math_fork). |
| `math_equation_animator.dart` | 10.7 KB | Animador de ecuaciones: transiciones suaves entre estados de la ecuación. |
| `class_card.dart` | 8.7 KB | Tarjeta de clase/materia con diseño premium. |
| `avatar_widget.dart` | 7 KB | Widget de avatar animado de Banny. |
| `interactive_math_element.dart` | 7.9 KB | Elemento matemático interactivo con estados de hover, selección y arrastre. |
| `draggable_math_piece.dart` | 5.8 KB | Pieza arrastrable con feedback visual (sombra, escala, colores). |
| `equals_portal.dart` | 4.9 KB | Portal animado del signo `=`: efecto visual al pasar bloques de un lado a otro. |
| `animated_slide.dart` | 5.4 KB | Slide animado para la presentación inicial. |
| `interactive_problem_card.dart` | 5.2 KB | Tarjeta de problema con interactividad. |
| `math_expression_display.dart` | 4.8 KB | Display de expresiones matemáticas con formato rico. |
| `animated_aurora.dart` | 3.6 KB | Fondo animado tipo aurora boreal (estética premium). |
| `smart_cube.dart` | 3 KB | Cubo 3D interactivo para visualización. |
| `interactive_board.dart` | 3.7 KB | Tablero interactivo simplificado. |
| `equation_drop_zone.dart` | 2.3 KB | Zona de drop para piezas de ecuación. |
| `drop_zone_widget.dart` | 1.6 KB | Widget genérico de zona de drop. |
| `math_piece.dart` | 2 KB | Pieza matemática visual básica. |

#### `widgets/exercise_templates/` — Plantillas de Ejercicios (11 archivos)
El corazón de la gamificación educativa:

| Template | Peso | Mecánica |
|----------|------|----------|
| `destruirecuaciones_conseleccion_template.dart` | **75.3 KB** | **"Destructor de Ecuaciones con Selección"**. El usuario mueve bloques de la ecuación; al mover incorrectamente, aparece un modal con taxonomía de errores (traidor_signo, orden_operaciones, etc.) y se envía al backend para registro y feedback. |
| `candymath_template.dart` | **74.7 KB** | **"CandyMath 3D"**. Estética "Gominola 3D" con animaciones procedurales de cancelación (shake → tint → shrink → layout collapse), carruseles elásticos, borde grueso 3D. Paso intermedio visual con colores diferenciados per tipo de acción. |
| `academia_ninja_template.dart` | **54.2 KB** | **"Academia Ninja"**. Mecánica de corte/swipe sobre ecuaciones. Niveles y pasos con tableros de ecuación cortables. |
| `dardos_template.dart` | **51.8 KB** | **"Dardos Matemáticos"**. Mecánica de lanzamiento de dardos para seleccionar respuestas. |
| `beatmath_template.dart` | **48 KB** | **"BeatMath"**. Motor basado en `CustomPaint` con renderizado de partículas, colisiones y estética Neón. Modal de pregunta que pausa el juego para validar el paso matemático. |
| `destructor_ecuaciones_template.dart` | **40.5 KB** | **"Destructor de Ecuaciones"**. Versión base del destructor sin selección múltiple. |
| `drag_drop_template.dart` | 6 KB | **"Drag & Drop"**. Template básico de arrastrar y soltar piezas. |
| `tap_destroy_template.dart` | 5.8 KB | **"Tap para Destruir"**. Toca las respuestas correctas. |
| `fill_blank_template.dart` | 4.8 KB | **"Rellenar Espacio"**. Completa el valor faltante. |
| `multiple_choice_template.dart` | 2.4 KB | **"Opción Múltiple"**. Selecciona la respuesta correcta. |
| `base_exercise_template.dart` | 0.9 KB | Clase base abstracta para todas las plantillas. |

#### `utils/`
*   `visual_styles.dart` (7.3 KB): Definiciones centralizadas de estilos visuales y colores del sistema de diseño.

---

### 2. El Backend (FastAPI) - `backend/`
El "Cerebro" que procesa la lógica, la memoria y la IA.

#### `main.py` (v3.0) — Orquestador Central (611 líneas)
*   Servidor **FastAPI** con lifecycle events (`asynccontextmanager`).
*   Sistema de **flags modulares**: `SIGNALS_ENABLED`, `PREDICTION_ENABLED`, `WEBSOCKET_ENABLED`, `AI_PROBLEM_GENERATION`, `TTS_ENABLED`, `PROFILE_ROUTES_ENABLED`.
*   Importación **try/except** de cada router para degradación graceful (el backend funciona aunque falten módulos).
*   CORS abierto para desarrollo (`allow_origins=["*"]`).
*   Crea tablas automáticamente en startup vía `Base.metadata.create_all()`.
*   **Endpoints directos**: `/api/solve`, `/api/hints`, `/api/topics`, `/api/problem/generate/adaptive`, `/health`.

#### `database/` — Persistencia
| Archivo | Descripción |
|---------|-------------|
| `models.py` (5.8 KB) | **6 tablas SQLAlchemy** (compatible PostgreSQL y SQLite): |
| | • `UserSession`: Sesiones con UUID y timestamps |
| | • `UserSignal`: Señales de comportamiento (tipo, metadata JSON, FK a session) |
| | • `CognitiveMarker`: Métricas cognitivas procesadas (tiempos, error_rate, estilo detectado, frustration/engagement/confidence levels) |
| | • `PedagogicalMemory`: **Memoria pedagógica** — qué funcionó (estilo explicación, visual, scaffolding) y qué NO (approaches fallidos) por tipo de problema |
| | • `UserProfile`: **Perfil agregado** — estadísticas, preferencias (estilo visual, rango de edad inferido, velocidad de aprendizaje, modalidad preferida, umbral de frustración, sesión óptima), ejes de personalización profunda (tono, scaffolding, contextos, intereses), mastery_scores y error_patterns |
| | • `SkillTracking`: **Seguimiento de habilidades** — mastery_score por tema (0-100), accuracy, tiempo promedio, intentos |
| `session.py` | Engine de SQLAlchemy y `SessionLocal` factory |
| `database.py` | Helper `get_db()` para dependency injection de FastAPI |

#### `math_engine/` — Motor Matemático
| Archivo | Peso | Descripción |
|---------|------|-------------|
| `solver.py` | 13.9 KB (329 líneas) | **MathSolver** — Resolución con SymPy. Normaliza expresiones (multiplicación implícita `2x`→`2*x`, exponentes `^`→`**`, paréntesis). Genera pasos detallados con emojis. **Genera puntos para gráficos** con NumPy (100 puntos, rango dinámico alrededor de la solución). |
| `generator.py` | 5 KB | **ProblemGenerator** — Generador legacy de problemas aleatorios por tema y dificultad. |
| `topics.py` | 0.9 KB | Definición de temas disponibles: aritmética, ecuaciones lineales, álgebra, cuadráticas, fracciones. |

#### `ai/` — Agentes de IA (6 archivos)
| Archivo | Estado | Descripción |
|---------|--------|-------------|
| `problem_generator_ai.py` | ✅ Implementado (5.5 KB) | **AIProblemGenerator** — Genera problemas adaptativos con OpenAI. Considera historial del usuario, conceptos dominados y débiles. |
| `exercise_agent.py` | ⬜ Scaffold (vacío) | Agente para generación dinámica de ejercicios gamificados. |
| `professor_agent.py` | ⬜ Scaffold (vacío) | Agente "profesor" para explicaciones detalladas. |
| `programmer_agent.py` | ⬜ Scaffold (vacío) | Agente que genera código/ejercicios programáticamente. |
| `tutor_orchestrator.py` | ⬜ Scaffold (vacío) | Orquestador de agentes (futuro sistema multi-agente). |
| `validator_agent.py` | ⬜ Scaffold (vacío) | Agente de validación de respuestas con IA. |

#### `api/` — Rutas de la API (7 archivos)
| Archivo | Peso | Descripción |
|---------|------|-------------|
| `websocket_routes.py` | **12.3 KB** | **Chat en tiempo real con Banny**. WebSocket `/ws/chat/{user_id}`. Usa **gpt-4o-mini** con JSON mode. **System prompt dinámico** que se adapta al perfil del usuario (tono, scaffolding, intereses) y al template activo (guiado/libre/desafio). **Ventana de contexto deslizante** de 6 mensajes. Maneja `progress_event` para actualizar SkillTracking. **Genera ejercicios dinámicos** (JSON skeletons) cuando el frontend solicita un tipo específico. |
| `problem_routes.py` | **16.2 KB** | Rutas de problemas: `/generate` (legacy), `/generate/adaptive` (OpenAI con fallback), `/solve`, `/hints`, `/topics`, **`/validar-paso`** (MVP de validación de pasos con taxonomía de errores: traidor_signo, orden_operaciones, operacion_inversa_incorrecta, peras_con_manzanas, omision_raiz_negativa, movimiento_invalido, expansion_innecesaria). |
| `profile_routes.py` | 3.2 KB | Rutas de perfil: guardar/cargar datos de onboarding y personalización profunda. |
| `tts_routes.py` | 4.5 KB | Rutas TTS: `/api/tts/synthesize` (WAV), `/api/tts/status`, `/api/tts/voices`. |
| `personalized_tutor.py` | 4.9 KB | Lógica de personalización del tutor basada en perfil. |
| `models.py` | 0.9 KB | Modelos Pydantic compartidos entre rutas. |

#### `services/` — Servicios del Backend
| Archivo | Peso | Descripción |
|---------|------|-------------|
| `signal_processor.py` | **7.9 KB** | **SignalProcessor** — Procesa señales con **Polars** (30x más rápido que Pandas). Calcula métricas cognitivas (tiempo promedio, tasa de error, uso de voz/texto/cámara, solicitudes de ayuda). **Detecta estilo visual** (Playful/Balanced/Minimal) con sistema de scoring ponderado. Target: <100ms por sesión. |
| `kokoro_service.py` | 4.8 KB | **KokoroTTS** — Text-to-Speech local con modelo ONNX (325 MB). Voz `ef_dora` en español. Sin costo de API. |

#### `intelligence/` — Inteligencia de Usuario
| Archivo | Peso | Descripción |
|---------|------|-------------|
| `user_profile.py` | **4.6 KB** | **UserIntelligenceProfile** — Memoria vectorial con **ChromaDB** + **SentenceTransformers** (`all-MiniLM-L6-v2`, 80MB). Almacena interacciones exitosas y fallidas como embeddings. Búsqueda por similaridad para reutilizar estrategias que funcionaron. Si el usuario no tiene historial, busca de usuarios similares. |

#### `prediction/` — Motor de Predicción
| Archivo | Peso | Descripción |
|---------|------|-------------|
| `intervention_engine.py` | **5.9 KB** | **InterventionEngine** — Predice probabilidad de confusión (0-1) ANTES del error. Usa: ratio tiempo actual vs. esperado (40%), señales de frustración (30%), tasa histórica de éxito (30%). **4 niveles de intervención**: ninguna (<0.3), pista visual sutil (0.3-0.6), pregunta socrática (0.6-0.8), ejemplo guiado completo (≥0.8). |

#### `routes/` — Rutas Adicionales
| Archivo | Descripción |
|---------|-------------|
| `signals.py` (9.5 KB) | Ingestión y consulta de señales: `/api/signals/ingest`, `/api/signals/ingest/batch`, `/api/signals/stats/{user_id}`, `/api/signals/session/{id}/process`. |
| `prediction.py` (2.8 KB) | Ruta de predicción de intervención: `/api/predict/intervention`. |
| `websocket.py` (1.6 KB) | WebSocket legacy (reemplazado por `api/websocket_routes.py`). |

#### `dashboard/`
*   `streamlit_app.py` (6.3 KB): Dashboard de monitoreo con **Streamlit** para visualizar métricas de usuarios, señales y progreso.

#### `models/` (backend)
*   `kokoro-v1.0.onnx` (325 MB): Modelo ONNX de Kokoro TTS.
*   `voices-v1.0.bin` (28 MB): Banco de voces para TTS.

---

---

## 🚀 Flujo de Aprendizaje Coordinado (4 Fases)

Este es el sistema central de enseñanza implementado en `EquationLab`:

1.  **Detección de Tema**: `EquationLab` analiza el chat del usuario (keywords + regex). Si detecta un tema (lineal, distributiva, factorización, cuadrática, cúbica), lanza el `LearningFlowOrchestrator`.
2.  **Fase 1: Tutorial de Abstracción**: Banny explica la teoría usando fórmulas abstractas (solo letras) para cimentar el concepto general. Sincronización labial (Lip-Sync) activa.
3.  **Fase 2: Ejemplo Guiado Dinámico**: El sistema transforma la fórmula en un ejemplo numérico real (`_generateConcreteScenes`). El avance es paso a paso controlado por el usuario (botón play/next disimulado).
4.  **Fase 3: Transición a la Acción**: El botón "¡Ahora intenta tú!" cierra el tutorial y activa la carga del ejercicio real.
5.  **Fase 4: Pantalla de Carga**: `TopicLoadingScreen` selecciona el mini-juego ideal.
6.  **Fase 5: Mini-Juego Hiper-Personalizado**: Lanzamiento de la plantilla gamificada.

---

## 🔌 El Flujo de Inteligencia (WebSocket)

```
┌─────────────┐     WebSocket      ┌──────────────┐
│  Flutter App │ ←───────────────→  │  FastAPI v3.0 │
│              │    JSON msgs       │              │
│  • Drag/Drop │                    │  • OpenAI    │
│  • Templates │                    │  • SymPy     │
│  • Signals   │                    │  • Polars    │
│              │                    │  • ChromaDB  │
└─────────────┘                    └──────────────┘
```

### Flujo de Resolución de Ejercicios:
1. **Dashboard** → el usuario selecciona template y ecuación (o la IA la genera vía `/generate/adaptive`).
2. **UnifiedBoardChatScreen** → carga el template seleccionado con la ecuación.
3. **Template** → el usuario interactúa (drag, tap, selección).
4. **Validación local** → `AnswerValidator` verifica formato, `CognitiveStateManager` actualiza estado.
5. **Señal al backend** → `SignalCollector` envía señal vía HTTP batch o WebSocket `progress_event`.
6. **Backend procesa** → `SignalProcessor` calcula métricas, `SkillTracking` se actualiza.
7. **Banny interviene** → Si el usuario se equivoca, el chat envía contexto al WebSocket, el system prompt se personaliza, y Banny responde con pregunta socrática.

### Flujo de Chat con Banny:
1. `BannyChatService` abre WebSocket a `/ws/chat/{user_id}`.
2. Cada mensaje incluye `context` con: `template`, `current_equation`, `recent_actions`, `recent_invalid_action`, `exercise_type`.
3. Backend construye **system prompt dinámico** basado en: perfil del usuario (DB), modo de sesión (guiado/libre/desafío), tipo de ejercicio.
4. OpenAI responde en **JSON mode** (`gpt-4o-mini`, max 300 tokens, 10s timeout).
5. Si `exercise_type` está presente, OpenAI genera un **skeleton de ejercicio** (JSON con equation, pieces, correct_answer).
6. **Ventana de contexto**: últimos 6 mensajes para optimizar costos de tokens.

---

## 🧠 Sistemas de Personalización

### 1. CognitiveStateManager (Frontend)
Máquina de estados de 3 niveles que se actualiza con cada respuesta:
*   **Exploración**: Mucho visual (0.9), pasos detallados, tono paciente, 3 ejemplos, celebrar casi todo.
*   **Construcción**: Balance (0.5), pasos normales, tono neutral, 1 ejemplo.
*   **Fluidez**: Mínimo visual (0.2), solo resultado, tono directo, sin ejemplos.

Reglas de transición:
*   2+ errores consecutivos → Exploración
*   Señal de confusión → Exploración
*   2+ correctos consecutivos desde Exploración → Construcción
*   3+ correctos consecutivos desde Construcción → Fluidez
*   Tasa de aciertos < 70% desde Fluidez → Construcción

### 2. SignalProcessor (Backend — Polars)
Detecta estilo visual basado en métricas comportamentales:
*   **Playful** (niños): tiempo < 10s + muchos errores + mucha voz + mucha ayuda.
*   **Balanced** (teens): métricas moderadas.
*   **Minimal** (adultos): tiempo > 30s + pocos errores + texto + autónomo.

### 3. InterventionEngine (Backend — Predictivo)
Predice confusión ANTES del error usando:
*   40% — Ratio tiempo actual vs. esperado (ChromaDB historial).
*   30% — Señales de frustración (errores consecutivos, taps rápidos).
*   30% — Tasa histórica de éxito en problemas similares.

### 4. PedagogicalMemory (Backend — ChromaDB)
Memoria vectorial que recuerda:
*   ✅ Qué estrategia de explicación funcionó para cada tipo de problema.
*   ✅ Qué tipo de visual fue efectivo (piezas, gráfico, recta numérica).
*   ❌ Qué enfoques fallaron y por qué.

### 5. Taxonomía de Errores Matemáticos
El `/validar-paso` clasifica errores con micro-feedback pedagógico:
| Error | Descripción |
|-------|-------------|
| `traidor_signo` | Olvidó cambiar signo al cruzar el `=` |
| `orden_operaciones` | Violó PEMDAS (sumó antes de dividir, etc.) |
| `operacion_inversa_incorrecta` | Usó la operación inversa equivocada |
| `peras_con_manzanas` | Sumó términos de diferente naturaleza |
| `omision_raiz_negativa` | Olvidó la solución negativa de √ |
| `movimiento_invalido` | Movimiento no permitido en el contexto actual |
| `expansion_innecesaria` | Expandió cuando podía factorizar |

---

## 📦 Dependencias Clave

### Flutter (`pubspec.yaml`)
| Paquete | Versión | Uso |
|---------|---------|-----|
| `provider` | ^6.1.1 | Gestión de estado global |
| `flutter_animate` | ^4.5.2 | Animaciones declarativas (shake, tint, shrink, slide) |
| `fl_chart` | ^1.1.0 | Gráficos interactivos de funciones |
| `flutter_math_fork` | ^0.7.4 | Renderizado LaTeX de ecuaciones |
| `web_socket_channel` | ^3.0.3 | WebSocket para chat en tiempo real |
| `just_audio` | ^0.9.40 | Reproducción de audio WAV (Kokoro TTS) |
| `google_fonts` | ^6.1.0 | Tipografías premium (Poppins, etc.) |
| `shimmer` | ^3.0.0 | Efectos de carga premium |
| `vibration` | ^3.1.5 | Feedback háptico en interacciones |
| `flutter_tts` | ^4.2.5 | TTS nativo del sistema |
| `speech_to_text` | ^7.0.0 | Reconocimiento de voz |
| `google_mlkit_text_recognition` | ^0.13.0 | OCR para leer ecuaciones de fotos |
| `image_picker` | ^1.0.7 | Captura de fotos para OCR |
| `shared_preferences` | ^2.5.3 | Almacenamiento local (UUID, preferencias) |
| `uuid` | ^4.5.2 | Generación de IDs únicos |
| `lottie` | ^3.3.1 | Animaciones Lottie |
| `path_provider` | ^2.1.5 | Directorio temporal para archivos de audio |
| `http` | ^1.6.0 | Cliente HTTP para API REST |

### Backend (`requirements.txt`)
| Paquete | Uso |
|---------|-----|
| `fastapi` + `uvicorn` | Servidor web asíncrono |
| `sqlalchemy` | ORM para PostgreSQL/SQLite |
| `sympy` | Álgebra simbólica (resolución, simplificación) |
| `numpy` | Generación de puntos para gráficos |
| `polars` | Procesamiento de señales (30x más rápido que Pandas) |
| `openai` | API de GPT-4o-mini |
| `chromadb` | Base de datos vectorial para memoria pedagógica |
| `sentence-transformers` | Embeddings para búsqueda semántica |
| `streamlit` | Dashboard de monitoreo |
| `kokoro` (ONNX) | TTS local sin costo |
| `pydantic` | Validación de datos |
| `python-dotenv` | Variables de entorno |

---

## 🚀 Funcionalidades Recientes Implementadas

### Phase 4: Estabilización y Activación
*   **UUID Persistente**: Se eliminaron los IDs estáticos. El sistema genera una identidad única por dispositivo que se sincroniza con PostgreSQL.
*   **Banny Proactivo**: El tutor ahora puede iniciar la conversación basándose en lo que el usuario está escribiendo en el tablero.
*   **Corrección de Animación**: Se corrigió el saludo de Banny para usar el brazo izquierdo en lugar de las orejas.

### Phase 5: Plantillas Premium e Interactividad Dual
1.  **BeatMath "Dynamic Levels"**: Motor basado en `CustomPaint` con progresión secuencial de niveles (lineal → distributiva → cuadrática → factorizada → cúbica). Sistema de "Modal de Pregunta" con pausa de juego.
2.  **CandyMath 3D & Procedural**: Estética "borde grueso 3D" con animación de cancelación encadenada (shake→tint→shrink→layout collapse). Paso intermedio visual con colores diferenciados.
3.  **EquationLab Refinement**: Coeficientes y exponentes como piezas independientes arrastrables. Ahora envía contexto de posición y operador al backend para feedback visual.

### Phase 6: Gamificación Extendida
4.  **Academia Ninja**: Mecánica de corte/swipe con niveles y pasos.
5.  **Dardos Matemáticos**: Mecánica de lanzamiento para selección de respuestas.
6.  **Destructor con Selección (MVP Core)**: Loop completo de validación de movimientos con taxonomía de errores y feedback del backend.

### Phase 7: Onboarding y Personalización Profunda
7.  **Encuesta de Onboarding**: Captura tono preferido, objetivo de aprendizaje, nivel de scaffolding, contextos del mundo real, intereses específicos.
8.  **System Prompt Dinámico**: El prompt de Banny se construye en tiempo real con datos del perfil del usuario.
9.  **SkillTracking via WebSocket**: `progress_event` actualiza mastery_score, accuracy y average_time por tema.

### Phase 8: Generación Dinámica de Ejercicios
10. **Skeletons de Ejercicio**: OpenAI genera JSON con estructura de ejercicio (ecuación, piezas, respuesta correcta, contexto temático) adaptado al tipo de template.
11. **Fallback Triple**: OpenAI → ProblemGenerator legacy → Problema hardcodeado.

### Phase 9: Centralización y Ecosistema de Aprendizaje
12. **LearningFlowOrchestrator**: Sistema modular que une tutoriales, carga y gamificación.
13. **Hiper-Personalización Visual**: El mini-juego final se selecciona comparando las afinidades visuales de la plantilla con los intereses del usuario (ej: si le gusta la música, prioriza BeatMath).
14. **Detección Robusta**: Soporte para más de 50 variaciones de keywords y expresiones regulares para detectar temas matemáticos complejos (mejorado para cuadráticas y cúbicas).
15. **IA con Contexto Visual**: Integración de la calculadora con renderizado LaTeX, detección de números y sincronización de voz con subtítulos en el tutorial.

### Phase 10: Pedagogía y Sincronización Realista
16. **Lip-Sync de Banny**: Sincronización labial basada en el stream de audio real del `TTSService`. Banny solo mueve la boca cuando hay sonido, mejorando la inmersión.
17. **Refactorización de Tutorial (3 Pasos)**: Evolución del tutorial hacia un modelo pedagógico de lo abstracto a lo concreto.
18. **Mapping Dinámico de Escenas**: Generador interno que mapea cualquier guión de letras a un ejemplo con números para todos los temas (lineal, cuadrática, etc.), eliminando la necesidad de guiones duplicados.
19. **Navegación Controlada**: Eliminación del modo interactivo confuso dentro del tutorial en favor de un flujo guiado paso a paso con control manual del usuario.
20. **Normalización Unicode Automática**: El backend ahora procesa y normaliza caracteres Unicode (² , ³) provenientes del frontend, evitando fallos de regex y garantizando compatibilidad universal.
21. **Descomposición de Bloques Granular**: Se eliminó el "fallback monolítico". Todas las ecuaciones (lineales, cuadráticas, cúbicas) se descomponen en piezas individuales interactivas (coeficientes, variables con potencias, operadores).
22. **Sincronización de Estado (blocks_before)**: Introducción del campo `blocks_before` en el protocolo de comunicación. Esto asegura que el "halo didáctico" (el brillo que indica qué arrastrar) apunte exactamente al número correcto desde el primer instante, evitando desajustes visuales entre cliente y servidor.
23. **Fidelidad de Estructura (Footprint Matching)**: El generador de ejercicios similares ahora respeta la complejidad de la entrada. Si el usuario ingresa una cúbica con coeficiente y constante (ej. 2x³+4), el sistema garantiza un reto generado con esa misma estructura exacta en lugar de simplificarla.
24. **Generación Aleatoria con Coherencia Pedagógica (Etapa 2)**: El motor del backend (`MathSolver`) genera números aleatorios inteligentes que garantizan **resultados enteros** (ej. raíces perfectas en cuadráticas/cúbicas) y pasos lógicos claros. Esto evita que el alumno se enfrente a decimales infinitos o errores de división por cero durante su primera práctica guiada.

---

## 🐛 Bugs y "Nuances" de Desarrollo

1.  **IP de Android**: Recordar el uso de `10.0.2.2` para desarrollo local en emulador.
2.  **SymPy & Syntax**: El backend espera multiplicaciones explícitas (`2*x`). El frontend debe sanitizar la entrada antes de enviarla. El `MathSolver.normalize_expression()` maneja esto automáticamente.
3.  **ChromaDB Config**: La base de datos vectorial + SentenceTransformer puede ser pesada (400MB+ en modelos); se recomienda correr solo en sistemas con más de 8GB de RAM.
4.  **Flutter Animate Overload**: Se han optimizado los triggers para que solo se animen los bloques activos.
5.  **Agentes AI vacíos**: Los archivos `exercise_agent.py`, `professor_agent.py`, `programmer_agent.py`, `tutor_orchestrator.py`, `validator_agent.py` están vacíos (scaffolds para futuro sistema multi-agente).
6.  **WebSocket único real**: Solo `api/websocket_routes.py` está activo. `routes/websocket.py` es legacy.
7.  **Doble definición de `/generate/adaptive`**: Existe tanto en `main.py` como en `api/problem_routes.py`; `problem_routes.py` toma precedencia cuando el router está habilitado.
8.  **equation_lab.dart (130KB)**: Archivo muy grande que maneja toda la lógica del sandbox. Candidato futuro para refactorización en sub-módulos.

---

## 📊 Métricas del Proyecto

| Métrica | Valor |
|---------|-------|
| Archivos Dart (lib/) | 88 |
| Archivos Python (backend/) | 52 |
| Templates de ejercicio | 11 |
| Tablas en DB | 6 |
| Providers | 4 globales + 2 de servicio |
| Endpoints REST | ~16 |
| Endpoints WebSocket | 1 (con manejo de progress_event) |
| Dependencias Flutter | 20 |
| Modelos ONNX | 1 (325 MB - Kokoro TTS) |
| SDK Dart | ^3.8.1 |
| Versión app | 1.0.0+1 |
| API version | v3.2.0 |

---

## 📝 Notas Finales
MathTutor v3.0 no es solo software; es una demostración de cómo la IA puede humanizar la educación. Cada línea de código está pensada para que el alumno se sienta *visto* y *apoyado* en su viaje de aprendizaje. Cada señal del usuario (cuánto tarda, en qué se equivoca, cómo interactúa) queda registrada para que el tutor sea cada vez más inteligente. ¡Bienvenido al código de MathTutor!
