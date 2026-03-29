# 🌟 Guía Completa de MathTutor (Banny AI)

¡Hola! Esta guía explica absolutamente todo sobre el proyecto: qué es, cómo funciona, por qué elegimos cada tecnología, y qué falta por construir. Está pensada para que cualquier persona —o cualquier IA— pueda entender el proyecto de punta a punta.

---

## 🌈 ¿Qué es MathTutor?

MathTutor es una **aplicación educativa de matemáticas hiper-personalizada**. No es una calculadora ni un quiz genérico. Es un ecosistema completo donde:

- **Banny**, un tutor de IA, te guía usando el **método socrático** (te hace preguntas en vez de darte respuestas).
- Las ecuaciones se convierten en **objetos físicos** que podés arrastrar, cortar, lanzar o destruir.
- El sistema **aprende de vos**: detecta tu nivel, tus errores frecuentes, tu tono preferido, y adapta todo (desde los colores hasta las explicaciones) en tiempo real.
- Hay **11 mini-juegos** diferentes para practicar matemáticas (desde puzzles de arrastrar hasta juegos de disparos con estética neón).

---

## 🏠 ¿Cómo está organizado el proyecto?

El proyecto tiene **dos mundos** que trabajan juntos:

### 1. 📱 El Frontend (la App) — Carpeta `lib/`

Es lo que el usuario ve y toca. Está construida con **Flutter** (lenguaje Dart). Se organiza así:

#### `screens/` — Las Pantallas (6 pantallas)
Son las "páginas" completas de la app. El usuario navega entre ellas:

| Pantalla | ¿Qué hace? |
|----------|------------|
| **Presentación** (`presentation_slide.dart`) | Slides de bienvenida que explican qué es MathTutor. Primera cosa que ves al abrir la app. |
| **Onboarding Visual** (`style_onboarding_screen.dart`) | Te pregunta qué estilo visual preferís: colorido y juguetón, equilibrado, o minimalista. |
| **Encuesta de Personalización** (`onboarding_survey_screen.dart`) | Encuesta profunda: ¿querés que Banny sea amigable o directo? ¿Te gustan los deportes, la música, el espacio? ¿Querés explicaciones paso a paso o solo pistas? Todo esto se guarda en tu perfil. |
| **Dashboard** (`modern_dashboard_screen.dart`) | **La pantalla principal**. Desde acá podés: escribir una ecuación manualmente, elegir un template de juego, seleccionar el modo de sesión (Exploración, Desafío, Libre). Es el cerebro de navegación. |
| **Chat con Banny** (`banny_chat_screen.dart`) | Chat standalone con el tutor IA. |
| **Tablero Unificado** (`unified_board_chat_screen.dart`) | Tablero interactivo + chat de Banny en la misma pantalla. Recibe la ecuación y el template elegido. |

**Flujo de navegación:**
```
Presentación → Onboarding Visual → Encuesta → Dashboard → Tablero/Chat
         ↑                                          ↓
         └──────────────── (volver) ────────────────┘
```

#### `widgets/exercise_templates/` — Los 11 Mini-Juegos
Cada template es un **mini-juego** con mecánica, estética y dificultad diferente:

| # | Template | Mecánica | Estética |
|---|----------|----------|----------|
| 1 | **Destructor con Selección** | Mover bloques de la ecuación. Si te equivocás, aparece un modal con el tipo de error (ej. "Traidor del Signo") y feedback personalizado. | Interfaz de selección |
| 2 | **CandyMath 3D** | Cancelar términos tocándolos. Animación encadenada: shake → tint → shrink → collapse. Paso intermedio con colores diferenciados. | Gominolas 3D con bordes gruesos y brillo |
| 3 | **Academia Ninja** | Cortar/swipear ecuaciones como un ninja. Niveles con pasos progresivos. | Temática ninja |
| 4 | **Dardos Matemáticos** | Lanzar dardos para seleccionar la respuesta correcta. | Tablero de dardos |
| 5 | **BeatMath** | Juego de disparos/colisiones con partículas neón. Modal que pausa el juego para validar pasos matemáticos. | Neón, CustomPaint, partículas |
| 6 | **Destructor de Ecuaciones** | Versión base: destruir bloques incorrectos. | Explosiones |
| 7 | **Drag & Drop** | Arrastrar piezas al lugar correcto. | Limpio, funcional |
| 8 | **Tap para Destruir** | Tocar las respuestas correctas rápido. | Arcade |
| 9 | **Rellenar Espacio** | Completar el valor faltante en la ecuación. | Puzzle |
| 10 | **Opción Múltiple** | Elegir entre opciones. | Quiz clásico |
| 11 | **EquationLab** | Sandbox libre donde las piezas son objetos físicos arrastrables. Portal animado al cruzar el `=`, transformación de operaciones inversas, coeficientes y exponentes como piezas separadas. | Laboratorio científico premium |

#### `services/` — Los Servicios (13 archivos)
Son los "mensajeros" que conectan la app con el backend y manejan lógica interna:

| Servicio | ¿Qué hace? |
|----------|------------|
| **AnswerValidator** | Validador inteligente que entiende múltiples formatos: `4`, `x=4`, `3/4`, `50%`, `sí`, `verdadero`. Tiene tolerancia para decimales (ε=0.01). |
| **CognitiveStateManager** | **Máquina de estados del cerebro del alumno**. Detecta si estás en Exploración (necesitás mucha guía), Construcción (vas entendiendo) o Fluidez (lo dominás). Cambia automáticamente según tus aciertos y errores. |
| **BannyChatService** | Cliente WebSocket que conecta con Banny en tiempo real. |
| **MathApiService** | Cliente HTTP para la API REST del backend (resolver, pistas, generar problemas). |
| **MathParser** | Parser de expresiones: convierte `2x+3=7` en un árbol de nodos que la app puede manipular como bloques. |
| **SignalCollector** | Recolecta todo lo que hacés: taps, tiempos, errores, si usás voz o texto. |
| **TTSService** | Text-to-Speech: Banny puede hablar usando Kokoro TTS local (sin costo) o TTS del sistema. |
| **MathEngineService** | Motor local de validación rápida (sin necesidad de backend). |
| **SignalService** | Envía las señales recolectadas al backend en batch. |
| **ProfileService** | Guarda/carga tu perfil de personalización. |
| **HyperpersonalizedTutorService** | Consulta el perfil completo al backend para personalizar la sesión. |

#### `providers/` — El Estado Global (6 archivos)
Guardan "la memoria de corto plazo" de la app mientras la usás:

| Provider | ¿Qué recuerda? |
|----------|----------------|
| **UserProvider** | Quién sos (UUID persistente), tu perfil, tu sesión actual. |
| **AdaptiveStyleProvider** | Cómo se ve la app ahora (colores, animaciones, nivel de detalle visual). |
| **BoardProvider** | Estado del tablero: qué piezas hay, dónde están, historial de movimientos. |
| **EquationProvider** | La ecuación en resolución: parsing, validación de cada paso. |
| **VisualStyleProvider** | Tema visual activo (playful/balanced/minimal). |
| **SesionMatematicaController** | Temporizador, contadores de progreso, modo actual (guiado/libre/desafío). |

#### `models/` — Los Moldes de Datos (16 archivos)
Definen la estructura de cada tipo de dato: `MathElement`, `BoardState`, `UserProfile`, `ChatMessage`, `UserSignal`, `EquationState`, `MathPiece`, `VisualStyle`, etc.

---

### 2. 🧠 El Backend (el Cerebro) — Carpeta `backend/`

Es donde vive la inteligencia, los cálculos y la memoria permanente. Está construido con **Python** (FastAPI).

#### `main.py` — El Orquestador (v3.0)
Arranca el servidor con **flags modulares**: si falta ChromaDB, el backend sigue funcionando sin predicción. Si falta OpenAI, usa el generador random. Cada módulo se importa con `try/except` para degradación graceful.

#### `math_engine/` — El Matemático Exacto
- **solver.py**: Resuelve ecuaciones con **SymPy** (álgebra simbólica rigurosa). Normaliza expresiones (`2x` → `2*x`), genera pasos intermedios con explicaciones, y produce 100 puntos para gráficos con **NumPy**.
- **generator.py**: Genera problemas aleatorios por tema y dificultad (sin IA).

#### `ai/` — La Inteligencia Artificial
- **problem_generator_ai.py**: Genera problemas adaptativos con **OpenAI**. Considera tu historial y ajusta dificultad.
- **5 agentes vacíos** (scaffolds para futuro): `exercise_agent`, `professor_agent`, `programmer_agent`, `tutor_orchestrator`, `validator_agent`.

#### `api/` — Las Rutas de la API
| Ruta | ¿Qué hace? |
|------|------------|
| **WebSocket** `/ws/chat/{user_id}` | Chat en tiempo real con Banny. System prompt dinámico que cambia según tu perfil, template activo y modo de sesión. Usa **gpt-4o-mini** con ventana de 6 mensajes. |
| **POST** `/api/problem/generate/adaptive` | Genera problema con IA (fallback a random si falla). |
| **POST** `/api/solve` | Resuelve ecuación con pasos detallados. |
| **POST** `/api/problem/validar-paso` | Valida un paso y clasifica el error con taxonomía pedagógica. |
| **POST** `/api/tts/synthesize` | Convierte texto a audio WAV con Kokoro TTS (voz local). |
| **POST** `/api/signals/ingest` | Recibe señales de comportamiento del usuario. |

#### `database/` — La Memoria Permanente (6 tablas)
| Tabla | ¿Qué guarda? |
|-------|-------------|
| `user_sessions` | Cada vez que abrís la app. |
| `user_signals` | Cada cosa que hacés (tap, error, tiempo, método de input). |
| `cognitive_markers` | Métricas procesadas: tiempo promedio, tasa de error, estilo detectado, niveles de frustración/engagement/confianza. |
| `pedagogical_memory` | Qué tipo de explicación te funcionó y cuál no, por tipo de problema. |
| `user_profiles` | Tu perfil completo: edad inferida, velocidad de aprendizaje, tono preferido, intereses, mastery scores. |
| `skill_tracking` | Tu dominio por tema: mastery_score (0-100), accuracy, tiempo promedio. |

#### `services/` — Servicios del Backend
- **SignalProcessor**: Procesa señales con **Polars** (30x más rápido que Pandas). Detecta tu estilo visual analizando velocidad, errores, uso de voz, y pedidos de ayuda.
- **KokoroTTS**: TTS local con modelo ONNX de 325 MB. Sin costo de API.

#### `intelligence/` — Memoria Vectorial
- **UserIntelligenceProfile**: Usa **ChromaDB** + **SentenceTransformers** para crear embeddings de cada interacción. Cuando enfrentás un problema nuevo, busca problemas similares que resolviste antes y reutiliza la estrategia que te funcionó.

#### `prediction/` — Motor Predictivo
- **InterventionEngine**: Predice si vas a confundirte *antes* de que cometas el error. Usa 3 señales (tiempo, frustración, historial) y decide entre 4 niveles de intervención: no hacer nada, pista visual sutil, pregunta socrática, o ejemplo guiado completo.

---

## 🏛️ La Arquitectura: Qué Usamos y Por Qué

### Diagrama General

```
┌─────────────────────────────────────────────────────┐
│                    USUARIO                          │
│         (toca, arrastra, habla, escribe)             │
└──────────────────────┬──────────────────────────────┘
                       │
          ┌────────────▼────────────────┐
          │   FLUTTER APP (Frontend)    │
          │                             │
          │  ┌─────────┐ ┌───────────┐  │
          │  │ Provider │ │ Services  │  │
          │  │ (Estado) │ │ (Conexión)│  │
          │  └─────────┘ └─────┬─────┘  │
          │                    │        │
          │  ┌─────────────────┴──────┐ │
          │  │ Widgets + Templates    │ │
          │  │ (11 mini-juegos)       │ │
          │  └────────────────────────┘ │
          └────────────┬────────────────┘
                       │
            HTTP REST + WebSocket
                       │
          ┌────────────▼────────────────┐
          │   FASTAPI (Backend)         │
          │                             │
          │  ┌──────┐  ┌────────────┐   │
          │  │ API  │  │ WebSocket  │   │
          │  │Routes│  │ (Banny AI) │   │
          │  └──┬───┘  └──────┬─────┘   │
          │     │             │         │
          │  ┌──▼─────────────▼──────┐  │
          │  │     LÓGICA CENTRAL    │  │
          │  │  ┌──────┐ ┌────────┐  │  │
          │  │  │SymPy │ │OpenAI  │  │  │
          │  │  │Engine│ │GPT-4o  │  │  │
          │  │  └──────┘ └────────┘  │  │
          │  │  ┌──────┐ ┌────────┐  │  │
          │  │  │Polars│ │ChromaDB│  │  │
          │  │  │Signal│ │Memory  │  │  │
          │  │  └──────┘ └────────┘  │  │
          │  └───────────────────────┘  │
          │           │                 │
          │  ┌────────▼──────────────┐  │
          │  │ PostgreSQL / SQLite   │  │
          │  │  (6 tablas)           │  │
          │  └───────────────────────┘  │
          └─────────────────────────────┘
```

### ¿Por qué Flutter? (Frontend)

| Razón | Explicación |
|-------|-------------|
| **Multiplataforma real** | Un solo código para Android, iOS, Web y Desktop. No necesitás mantener 4 apps. |
| **Rendimiento nativo** | Flutter compila a código nativo (no usa WebView como React Native antiguo). Las animaciones complejas de los templates (partículas, 3D, CustomPaint) corren a 60fps. |
| **Widget tree** | Todo es un widget. Esto hace que los 11 templates sean componentes reutilizables y la UI sea extremadamente modular. |
| **Hot Reload** | Cambios en el código se reflejan al instante sin perder el estado. Ideal para iterar en las animaciones de los templates. |
| **Ecosistema rico** | Paquetes como `flutter_animate` (animaciones), `fl_chart` (gráficos), `flutter_math_fork` (LaTeX) existen y son maduros. |

### ¿Por qué Provider? (Estado)

| Razón | Explicación |
|-------|-------------|
| **Simplicidad** | Para un equipo pequeño, Provider es directo: `ChangeNotifier` + `MultiProvider`. Riverpod es más poderoso pero más complejo. |
| **Suficiente** | 4 providers globales cubren todo: usuario, estilo visual, tablero, adaptación. No necesitamos reactividad más granular todavía. |
| **Official** | Recomendado por el equipo de Flutter. Gran documentación y comunidad. |

> *Nota: `flutter_riverpod` está listado en pubspec.yaml como dependencia pero actualmente se usa `provider` para el estado principal.*

### ¿Por qué FastAPI? (Backend)

| Razón | Explicación |
|-------|-------------|
| **Asíncrono nativo** | WebSockets + llamadas a OpenAI son operaciones I/O-bound. FastAPI con `async/await` las maneja sin bloquear el servidor. |
| **Validación automática** | Pydantic valida cada request/response con tipos. Si Flutter envía un JSON malformado, el error es claro y descriptivo. |
| **Documentación gratis** | `/docs` genera Swagger UI automáticamente. Perfecto para debug y testing. |
| **Rápido** | Basado en Starlette/Uvicorn. Es uno de los frameworks Python más rápidos. |
| **Ecosistema AI** | Python es el idioma de la IA. SymPy, OpenAI, ChromaDB, Polars, SentenceTransformers... todo es nativo. |

### ¿Por qué SymPy + OpenAI? (Motor dual)

Esta es una decisión **crítica** de arquitectura:

```
 ┌──────────────────────────────┐    ┌──────────────────────────────┐
 │        SymPy (GRATIS)        │    │     OpenAI (TIENE COSTO)     │
 │                              │    │                              │
 │  • Resolver ecuaciones       │    │  • Generar problemas         │
 │  • Validar pasos             │    │  • Crear historias temáticas │
 │  • Generar gráficos          │    │  • Responder como Banny      │
 │  • Normalizar expresiones    │    │  • Clasificar errores        │
 │                              │    │                              │
 │  100% determinista           │    │  Creativo y personalizado    │
 │  Sin internet                │    │  Requiere API key            │
 │  Resultado siempre correcto  │    │  Resultado variable          │
 └──────────────────────────────┘    └──────────────────────────────┘
```

**¿Por qué no usar SOLO OpenAI?** Porque GPT puede inventar respuestas incorrectas (alucinaciones). Las matemáticas requieren exactitud. SymPy nunca se equivoca en `2x + 5 = 13 → x = 4`.

**¿Por qué no usar SOLO SymPy?** Porque no puede crear una historia sobre Harry Potter donde los números son pociones mágicas, ni puede detectar que te sentís frustrado y cambiar el tono a algo más amable.

**Resultado**: SymPy para la verdad matemática, OpenAI para la experiencia humana. Lo mejor de ambos mundos.

### ¿Por qué Polars? (en vez de Pandas)

| Polars | Pandas |
|--------|--------|
| ⚡ 30x más rápido en operaciones vectorizadas | Más lento pero más conocido |
| 💾 Menos uso de memoria | Consume más RAM |
| 🔒 Inmutable por defecto (menos bugs) | Mutable (más errores sutiles) |

MathTutor procesa señales en **<100ms por sesión**. Con cientos de señales por usuario, Polars es esencial.

### ¿Por qué ChromaDB + SentenceTransformers? (Memoria vectorial)

El problema: *"Este alumno resolvió un problema de fracciones hace 3 meses usando la estrategia de 'pizza cortada en pedazos'. ¿Cómo encontrar esa información hoy?"*

- **SentenceTransformers** convierte el texto del problema en un **vector numérico** (embedding).
- **ChromaDB** guarda esos vectores y puede buscar **por similitud** (no por keywords exactas).
- Cuando el alumno enfrenta un problema nuevo, se buscan problemas similares del pasado y se reutiliza la estrategia que funcionó.

Esto es lo que hace que Banny "recuerde" y mejore con el tiempo.

### ¿Por qué Kokoro TTS? (en vez de Google Cloud TTS / ElevenLabs)

| Kokoro | Cloud TTS |
|--------|-----------|
| ✅ Sin costo por request | 💰 $4-16 por millón de chars |
| ✅ Sin internet (ONNX local) | ❌ Requiere conexión |
| ✅ Privacidad total | ❌ Audio va a servidores externos |
| ⚠️ Modelo de 325 MB | ✅ Sin almacenamiento local |
| ⚠️ Calidad buena pero no premium | ✅ Calidad premium |

Para un proyecto educativo con muchos usuarios, el costo acumulado de Cloud TTS sería insostenible. Kokoro corre local y es gratis.

### ¿Por qué PostgreSQL + SQLite? (dual compatible)

- **Desarrollo**: SQLite (un solo archivo, sin instalar nada).
- **Producción**: PostgreSQL (concurrencia, escalabilidad, JSON nativo).
- Los modelos SQLAlchemy son compatibles con ambos. El cambio es solo cambiar la URL de conexión en `.env`.

---

## 🔮 ¿Qué Falta por Agregar? (Roadmap de Mejoras)

### 🔴 CRÍTICAS — Necesarias para un MVP funcional

#### 1. **Sistema Multi-Agente de IA**
Los 5 archivos de agentes (`exercise_agent.py`, `professor_agent.py`, `programmer_agent.py`, `tutor_orchestrator.py`, `validator_agent.py`) están **vacíos**. Implementarlos significaría:
- **TutorOrchestrator**: Coordina qué agente responde según el contexto.
- **ExerciseAgent**: Genera ejercicios dinámicos con estructura de juego completa.
- **ValidatorAgent**: Valida respuestas usando IA + SymPy combinados (más inteligente que el validador actual por keywords).
- **ProfessorAgent**: Genera explicaciones extensas cuando el alumno pide "explicame de cero".
- **ProgrammerAgent**: Genera código/visualizaciones programáticamente.

#### 2. **Testing Automatizado**
No hay tests unitarios ni de integración. Se necesita:
- Tests de `AnswerValidator` con edge cases (fracciones negativas, decimales periódicos).
- Tests de `MathSolver` para ecuaciones cuadráticas, sistemas, etc.
- Tests de WebSocket para verificar el flujo completo.
- Widget tests para los templates.

#### 3. **Manejo de Errores Robusto**
- El WebSocket no tiene reconexión automática si se cae.
- No hay retry logic en las llamadas HTTP.
- Si OpenAI falla, el fallback funciona pero el usuario no recibe feedback claro.

#### 4. **Refactorización de `equation_lab.dart` (130KB)**
Este archivo es demasiado grande. Debería dividirse en:
- `equation_lab_state.dart` (estado y lógica)
- `equation_lab_pieces.dart` (widgets de piezas)
- `equation_lab_animations.dart` (animaciones)
- `equation_lab_validation.dart` (validación de movimientos)

---

### 🟡 IMPORTANTES — Mejoran significativamente la experiencia

#### 5. **Modo Offline Completo**
Actualmente, sin backend la app pierde: chat con Banny, generación de problemas, tracking de progreso. Se podría:
- Cachear los últimos 20 problemas generados.
- Usar un modelo de IA local pequeño (Phi-3 mini) para respuestas básicas.
- Sincronizar señales cuando vuelva la conexión.

#### 6. **Sistema de Logros y Gamificación**
Falta un sistema de:
- 🏆 Badges/insignias por hitos (ej. "Resolver 10 ecuaciones sin error").
- 🔥 Racha diaria (streak).
- 📊 Gráfico de progreso visible para el alumno.
- 🎁 Recompensas desbloqueables (nuevos temas, avatares de Banny).

#### 7. **Modo Profesor/Dashboard Docente**
Un panel web (Streamlit ya existe pero básico) donde el profesor pueda:
- Ver el progreso de cada alumno.
- Asignar ejercicios específicos.
- Ver patrones de error de toda la clase.
- Recibir alertas cuando un alumno lleva muchos errores.

#### 8. **Soporte Multi-Idioma**
La app está 100% en español. Agregar:
- Internacionalización (i18n) del frontend.
- System prompts de Banny en múltiples idiomas.
- Detección automática de idioma.

#### 9. **Autenticación Real**
Actualmente el usuario se identifica por UUID del dispositivo. No hay login. Se necesita:
- Login con Google/Apple (Firebase Auth).
- Sincronización de progreso entre dispositivos.
- Perfiles familiares (varios hijos en un mismo celular).

---

### 🟢 NICE TO HAVE — Diferenciadoras de mercado

#### 10. **Reconocimiento de Escritura a Mano (OCR Mejorado)**
Ya hay `google_mlkit_text_recognition` pero no está integrado al flujo principal. La idea:
- El alumno escribe la ecuación en papel.
- Saca foto con la cámara.
- La app la parsea y la carga en el tablero.

#### 11. **Generación de Videos Explicativos**
Banny podría generar mini-videos animados explicando un concepto, usando las mismas animaciones de los templates pero pregrabadas.

#### 12. **Comunidad / Social Learning**
- Desafíos entre amigos.
- Ranking semanal.
- Compartir logros en redes sociales.

#### 13. **Integración con LMS (Moodle, Google Classroom)**
Para que los profesores puedan asignar MathTutor como tarea desde su plataforma habitual.

#### 14. **Modelo Predictivo con ML Real**
El `InterventionEngine` actual usa heurísticas simples (if/else). Se podría entrenar un modelo de ML real con los datos acumulados para predecir confusión con mayor precisión.

#### 15. **Accessibility (A11y)**
- Screen reader support.
- Alto contraste.
- Control por voz completo.
- Ajuste de tamaño de fuente.

---

## 📊 Resumen del Estado Actual

```
┌─────────────────────────────────────────────────┐
│              ESTADO DEL PROYECTO                │
├─────────────────────────────────────────────────┤
│                                                 │
│  ✅ IMPLEMENTADO:                               │
│   • 11 templates de ejercicios                  │
│   • Chat en tiempo real con Banny (OpenAI)      │
│   • Motor matemático SymPy + gráficos           │
│   • Onboarding con personalización profunda     │
│   • Signal tracking + procesamiento Polars      │
│   • 6 tablas de DB con tracking completo        │
│   • TTS local con Kokoro                        │
│   • Estado cognitivo adaptativo                 │
│   • Taxonomía de errores matemáticos            │
│   • Validador multi-formato de respuestas       │
│                                                 │
│  ⬜ PENDIENTE:                                   │
│   • Sistema multi-agente de IA                  │
│   • Testing automatizado                        │
│   • Modo offline                                │
│   • Autenticación real                          │
│   • Gamificación (logros, rachas, badges)        │
│   • Dashboard docente completo                  │
│   • Multi-idioma                                │
│   • Refactorización de archivos grandes         │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 💡 Principios de Diseño

1. **IA para lo creativo, SymPy para lo correcto** — Nunca confiar en GPT para cálculos matemáticos.
2. **Degradación graceful** — Si un módulo falla, los demás siguen funcionando.
3. **Señales, no formularios** — En vez de preguntarle al usuario "¿cómo te sentís?", el sistema lo deduce de su comportamiento.
4. **Personalización invisible** — El usuario no sabe que la app se está adaptando; simplemente "le funciona mejor" con el tiempo.
5. **Costo sostenible** — SymPy gratis para cálculos, Kokoro gratis para voz, OpenAI solo para lo que solo IA puede hacer.

---

¡Y eso es todo! Esta guía es un mapa completo del proyecto. Si en el futuro agregamos nuevas partes, las iremos sumando acá.
