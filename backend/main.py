# backend/main.py
"""
MathTutor API v3.0 - HIPERPERSONALIZADO
Backend con PostgreSQL + Polars + ChromaDB + FastAPI
"""
import sys
import os
from pathlib import Path
from dotenv import load_dotenv

# Agregar backend al path
sys.path.insert(0, str(Path(__file__).parent))

# ⭐ CARGAR VARIABLES DE ENTORNO
load_dotenv(Path(__file__).parent / ".env")
print(f"📂 Cargando .env desde: {Path(__file__).parent / '.env'}")
print(f"   OPENAI_API_KEY configurado: {'✅' if os.getenv('OPENAI_API_KEY') else '❌'}")
print(f"   DATABASE_URL configurado: {'✅' if os.getenv('DATABASE_URL') else '❌'}")

# Importar dependencias de base de datos ahora que las variables de entorno están cargadas
from database.database import get_db
from database.session import engine
from database.models import Base, UserSession, UserSignal, CognitiveMarker, PedagogicalMemory, UserProfile

from sqlalchemy.orm import Session
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import uvicorn


# Importar math engine
from math_engine.solver import MathSolver


# ==================== MODELOS PYDANTIC ====================


class SolveMathRequest(BaseModel):
    expression: str
    show_steps: bool = True


class MathStepResponse(BaseModel):
    step_number: int
    expression: str
    explanation: str
    latex: Optional[str] = None


class MathSolutionResponse(BaseModel):
    expression: str
    solution: str
    steps: List[MathStepResponse]
    hints: List[str]
    latex_steps: Optional[List[str]] = None
    graph_data: Optional[Dict[str, Any]] = None


# ⭐ NUEVO: Modelo para generación adaptativa
class GenerateAdaptiveProblemRequest(BaseModel):
    user_id: str
    topic: str = "linear_equations"
    difficulty: str = "medium"


class AdaptiveProblemResponse(BaseModel):
    expression: str
    topic: str
    difficulty: str
    expected_time: int
    hint: Optional[str] = None
    answer: str
    generated_by: str = "openai"


# ==================== IMPORTAR ROUTERS ====================


PROBLEM_ROUTES_ENABLED = False
SIGNALS_ENABLED = True
PREDICTION_ENABLED = False
WEBSOCKET_ENABLED = True
AI_PROBLEM_GENERATION = True  # ⭐ NUEVO FLAG
TTS_ENABLED = False  # ⭐ KOKORO TTS
PROFILE_ROUTES_ENABLED = False


# Router de problemas (legacy)
try:
    from api.problem_routes import router as problem_router
    PROBLEM_ROUTES_ENABLED = True
    print("✅ api.problem_routes importado (incluye /check, /adaptive, /legacy)")
except ImportError as e:
    print(f"⚠️ api.problem_routes no disponible: {e}")

# Router de perfiles (hiperpersonalizacion)
try:
    from api.profile_routes import router as profile_router
    PROFILE_ROUTES_ENABLED = True
    print("✅ api.profile_routes importado (Onboarding/Perfiles)")
except ImportError as e:
    print(f"⚠️ api.profile_routes no disponible: {e}")


# Router de señales (tracking)
try:
    from routes.signals import router as signals_router
    SIGNALS_ENABLED = True
    print("✅ routes.signals importado")
except ImportError as e:
    print(f"⚠️ routes.signals no disponible: {e}")


# ⭐ NUEVO: Router de predicción (hiperpersonalización)
try:
    from routes.prediction import router as prediction_router
    PREDICTION_ENABLED = True
    print("✅ routes.prediction importado (HIPERPERSONALIZACIÓN)")
except ImportError as e:
    print(f"⚠️ routes.prediction no disponible: {e}")


# ⭐ NUEVO: Router de WebSocket (tiempo real)
try:
    from api.websocket_routes import router as websocket_router
    WEBSOCKET_ENABLED = True
    print("✅ api.websocket_routes importado (TIEMPO REAL - BANNY CHAT)")
except ImportError as e:
    print(f"⚠️ api.websocket_routes no disponible: {e}")


# ⭐ NUEVO: Importar generador de problemas con IA
try:
    from ai.problem_generator_ai import AIProblemGenerator
    AI_PROBLEM_GENERATION = True
    print("✅ ai.problem_generator_ai importado (OPENAI)")
except ImportError as e:
    print(f"⚠️ ai.problem_generator_ai no disponible: {e}")
    print("   Usando generador legacy (random)")
    AI_PROBLEM_GENERATION = False


# ⭐ NUEVO: Router Kokoro TTS
try:
    from api.tts_routes import router as tts_router
    TTS_ENABLED = True
    print("✅ api.tts_routes importado (KOKORO TTS - af_jessica)")
except ImportError as e:
    print(f"⚠️ api.tts_routes no disponible: {e}")


# ==================== LIFECYCLE EVENTS ====================


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Eventos de inicio y cierre de la aplicación"""
    global PREDICTION_ENABLED
    
    print("=" * 60)
    print("🚀 MATHTUTOR API v3.0 - HIPERPERSONALIZADO")
    print("=" * 60)
    
    # Crear tablas en PostgreSQL
    try:
        Base.metadata.create_all(bind=engine)
        print("✅ PostgreSQL: Tablas verificadas/creadas")
        print("   - user_sessions")
        print("   - user_signals")
        print("   - cognitive_markers")
        if PREDICTION_ENABLED:
            print("   - pedagogical_memory ⭐ NUEVA")
            print("   - user_profiles ⭐ NUEVA")
    except Exception as e:
        print(f"⚠️ PostgreSQL: Error - {e}")
    
    # Verificar ChromaDB
    if PREDICTION_ENABLED:
        try:
            import chromadb
            client = chromadb.PersistentClient(path="./chroma_db")
            print("✅ ChromaDB: Conectado (./chroma_db)")
        except ImportError:
            print(f"⚠️ ChromaDB: No instalado (optional) - pip install chromadb")
            print("   PREDICTION_ENABLED será forzado a False")
            PREDICTION_ENABLED = False
        except Exception as e:
            print(f"⚠️ ChromaDB: Error - {e}")
    
    print("=" * 60)
    print("📡 MÓDULOS ACTIVOS:")
    print(f"   Signal Tracking:     {'✅ HABILITADO' if SIGNALS_ENABLED else '❌ DESHABILITADO'}")
    print(f"   Math Solver:         {'✅ HABILITADO' if PROBLEM_ROUTES_ENABLED else '✅ HABILITADO (legacy)'}")
    print(f"   Prediction Engine:   {'✅ HABILITADO ⭐' if PREDICTION_ENABLED else '❌ DESHABILITADO'}")
    print(f"   WebSocket Real-Time: {'✅ HABILITADO ⭐' if WEBSOCKET_ENABLED else '❌ DESHABILITADO'}")
    print(f"   AI Problem Generator:{'✅ HABILITADO ⭐ (OpenAI)' if AI_PROBLEM_GENERATION else '❌ DESHABILITADO (usando random)'}")
    print(f"   Kokoro TTS (af_jessica):{'✅ HABILITADO ⭐' if TTS_ENABLED else '❌ DESHABILITADO'}")
    print("=" * 60)
    print("📋 ENDPOINTS DISPONIBLES:")
    print("")
    print("  🔹 GENERALES:")
    print("    - GET  /                    → Info general")
    print("    - GET  /health              → Health check")
    print("    - GET  /docs                → Documentación interactiva")
    print("")
    print("  🔹 MATH SOLVER (Legacy):")
    print("    - POST /api/solve           → Resolver expresión")
    print("    - POST /api/hints           → Obtener pistas")
    print("    - GET  /api/topics          → Listar temas")
    
    if PROBLEM_ROUTES_ENABLED:
        print("")
        print("  🔹 PROBLEM ROUTES:")
        print("    - POST /api/problem/generate → Generar problemas (legacy)")
        print("    - POST /api/problem/solve    → Resolver (nuevo)")
        print("    - GET  /api/problem/topics   → Temas disponibles")
    
    # ⭐ NUEVO: Endpoint de generación adaptativa
    if AI_PROBLEM_GENERATION:
        print("")
        print("  🔹 AI PROBLEM GENERATION ⭐:")
        print("    - POST /api/problem/generate/adaptive → Generar problema adaptativo (OpenAI)")
    
    if SIGNALS_ENABLED:
        print("")
        print("  🔹 SIGNAL TRACKING:")
        print("    - POST /api/signals/ingest         → Capturar señal")
        print("    - POST /api/signals/ingest/batch   → Batch de señales")
        print("    - GET  /api/signals/stats/{id}     → Stats del usuario")
        print("    - GET  /api/signals/session/{id}/process → Procesar sesión")
    
    if PREDICTION_ENABLED:
        print("")
        print("  🔹 HIPERPERSONALIZACIÓN ⭐:")
        print("    - POST /api/predict/intervention   → Predecir intervención")
    
    if WEBSOCKET_ENABLED:
        print("")
        print("  🔹 TIEMPO REAL ⭐:")
        print("    - WS   /ws/tutor/{user_id}         → WebSocket del tutor")
    
    if TTS_ENABLED:
        print("")
        print("  🔹 KOKORO TTS ⭐ (af_jessica - local, sin costo):")
        print("    - POST /api/tts/synthesize          → Texto → audio WAV")
        print("    - GET  /api/tts/status              → Estado del modelo")
        print("    - GET  /api/tts/voices              → Voces disponibles")
    
    print("=" * 60)
    print("🌐 Servidor: http://localhost:8000")
    print("📚 Documentación: http://localhost:8000/docs")
    print("=" * 60)
    
    yield  # Aquí corre la aplicación
    
    print("\n👋 MathTutor API cerrando...")


# ==================== FASTAPI APP ====================


app = FastAPI(
    title="MathTutor API - Hiperpersonalizado",
    description="Backend con PostgreSQL + Polars + ChromaDB + FastAPI",
    version="3.0.0",
    lifespan=lifespan
)


# ==================== CORS ====================


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especificar dominios
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== INCLUIR ROUTERS ====================


if PROBLEM_ROUTES_ENABLED:
    app.include_router(problem_router)

if SIGNALS_ENABLED:
    app.include_router(signals_router)

if PROFILE_ROUTES_ENABLED:
    app.include_router(profile_router)

# ⭐ NUEVOS ROUTERS
if PREDICTION_ENABLED:
    app.include_router(prediction_router)

if WEBSOCKET_ENABLED:
    app.include_router(websocket_router)

if TTS_ENABLED:
    app.include_router(tts_router)


# ==================== ROOT ENDPOINTS ====================


@app.get("/")
async def root():
    """Información general de la API"""
    endpoints = ["/health", "/docs", "/api/solve", "/api/hints", "/api/topics"]
    
    if PROBLEM_ROUTES_ENABLED:
        endpoints.extend(["/api/problem/generate", "/api/problem/solve"])
    
    if AI_PROBLEM_GENERATION:
        endpoints.append("/api/problem/generate/adaptive")
    
    if SIGNALS_ENABLED:
        endpoints.extend(["/api/signals/ingest", "/api/signals/stats/{user_id}"])
    
    if PREDICTION_ENABLED:
        endpoints.append("/api/predict/intervention")
    
    if WEBSOCKET_ENABLED:
        endpoints.append("/ws/tutor/{user_id}")
    
    return {
        "app": "MathTutor API - Hiperpersonalizado",
        "version": "3.0.0",
        "status": "running",
        "features": {
            "math_solver": True,
            "signal_tracking": SIGNALS_ENABLED,
            "postgresql": True,
            "polars_processing": SIGNALS_ENABLED,
            "chromadb": PREDICTION_ENABLED,
            "prediction_engine": PREDICTION_ENABLED,
            "websocket_realtime": WEBSOCKET_ENABLED,
            "ai_problem_generation": AI_PROBLEM_GENERATION,
            "streamlit_dashboard": True
        },
        "endpoints": endpoints
    }


@app.get("/health")
async def health_check():
    """Health check con verificación de PostgreSQL y ChromaDB"""
    
    # Verificar conexión a PostgreSQL
    db_status = "unknown"
    try:
        from database.session import SessionLocal
        db = SessionLocal()
        db.execute("SELECT 1")
        db.close()
        db_status = "healthy"
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"
    
    # Verificar ChromaDB (solo si está habilitado)
    chroma_status = "disabled"
    if PREDICTION_ENABLED:
        try:
            import chromadb
            client = chromadb.PersistentClient(path="./chroma_db")
            client.heartbeat()  # Test de conexión
            chroma_status = "healthy"
        except ImportError:
            chroma_status = "not_installed (optional)"
        except Exception as e:
            chroma_status = f"unhealthy: {str(e)}"
    
    # ⭐ NUEVO: Verificar OpenAI
    openai_status = "disabled"
    if AI_PROBLEM_GENERATION:
        try:
            from openai import OpenAI
            # No hacer llamada real, solo verificar importación
            openai_status = "ready"
        except ImportError:
            openai_status = "not_installed"
    
    overall_status = "healthy" if db_status == "healthy" else "degraded"
    
    return {
        "status": overall_status,
        "version": "3.0.0",
        "components": {
            "api": "operational",
            "database": db_status,
            "chromadb": chroma_status,
            "math_engine": "operational",
            "signal_processor": "operational" if SIGNALS_ENABLED else "disabled",
            "prediction_engine": "operational" if PREDICTION_ENABLED else "disabled",
            "websocket": "operational" if WEBSOCKET_ENABLED else "disabled",
            "openai_generator": openai_status
        }
    }


# ==================== ⭐ NUEVO: GENERACIÓN ADAPTATIVA DE PROBLEMAS ====================


@app.post("/api/problem/generate/adaptive", response_model=AdaptiveProblemResponse)
async def generate_adaptive_problem(
    request: GenerateAdaptiveProblemRequest,
    db: Session = Depends(get_db)
):
    """
    ⭐ NUEVO: Genera problema ADAPTATIVO con OpenAI
    
    - Analiza historial del usuario
    - Ajusta dificultad según desempeño
    - Usa estrategias que le funcionaron antes
    """
    
    if not AI_PROBLEM_GENERATION:
        raise HTTPException(
            status_code=503,
            detail="AI Problem Generation no está habilitado. Instalar OpenAI: pip install openai"
        )
    
    try:
        print(f"📝 Generando problema adaptativo para {request.user_id}")
        print(f"   Tema: {request.topic}, Dificultad base: {request.difficulty}")
        
        # 1. Obtener historial del usuario
        user_history = _get_user_history(request.user_id, db)
        
        # 2. Generar problema con IA
        generator = AIProblemGenerator()
        problem = generator.generate_adaptive_problem(
            user_id=request.user_id,
            topic=request.topic,
            difficulty=request.difficulty,
            user_history=user_history
        )
        
        print(f"✅ Problema generado: {problem.get('expression', '')}")
        
        # 3. Convertir a formato de respuesta
        response = AdaptiveProblemResponse(
            expression=problem.get("expression", ""),
            topic=problem.get("topic", request.topic),
            difficulty=problem.get("difficulty", request.difficulty),
            expected_time=problem.get("expected_time", 30),
            hint=problem.get("hint"),
            answer=problem.get("answer", ""),
            generated_by="openai"
        )
        
        return response
        
    except Exception as e:
        print(f"❌ Error generando problema adaptativo: {e}")
        
        # Fallback: usar generador legacy
        print("⚠️ Fallback a generador legacy (random)")
        return _generate_fallback_problem(request)


def _get_user_history(user_id: str, db: Session) -> Dict:
    """
    Obtiene historial del usuario de PostgreSQL
    """
    try:
        # Obtener señales del usuario
        signals = db.query(UserSignal).filter(
            UserSignal.session_id.like(f"{user_id}%")
        ).order_by(UserSignal.timestamp.desc()).limit(50).all()
        
        if not signals:
            return {
                "solved_count": 0,
                "last_error_type": "ninguno",
                "mastered_concepts": [],
                "weak_concepts": [],
                "avg_time_per_problem": 30
            }
        
        # Analizar señales
        problem_complete_count = len([s for s in signals if s.signal_type == "problem_complete"])
        problem_error_count = len([s for s in signals if s.signal_type == "problem_error"])
        
        return {
            "solved_count": problem_complete_count,
            "last_error_type": "algebra" if problem_error_count > 3 else "ninguno",
            "mastered_concepts": ["arithmetic", "basic_algebra"] if problem_complete_count > 5 else [],
            "weak_concepts": ["fractions"] if problem_error_count > 2 else [],
            "avg_time_per_problem": 25 if problem_complete_count > 5 else 40
        }
        
    except Exception as e:
        print(f"⚠️ Error obteniendo historial: {e}")
        return {
            "solved_count": 0,
            "last_error_type": "ninguno",
            "mastered_concepts": [],
            "weak_concepts": [],
            "avg_time_per_problem": 30
        }


def _generate_fallback_problem(request: GenerateAdaptiveProblemRequest) -> AdaptiveProblemResponse:
    """
    Fallback si OpenAI falla: usar generador legacy
    """
    try:
        from math_engine.generator import ProblemGenerator
        
        problems = ProblemGenerator.generate_by_topic(
            request.topic,
            request.difficulty,
            count=1
        )
        
        if problems:
            problem = problems[0]
            return AdaptiveProblemResponse(
                expression=problem.get("expression", "2x + 3 = 7"),
                topic=problem.get("topic", request.topic),
                difficulty=problem.get("difficulty", request.difficulty),
                expected_time=30,
                hint="Aislá la x moviendo los números",
                answer=problem.get("answer", "x = 2"),
                generated_by="legacy_random"
            )
    except Exception as e:
        print(f"⚠️ Error en fallback: {e}")
    
    # Último recurso: problema hardcodeado
    return AdaptiveProblemResponse(
        expression="2x + 5 = 13",
        topic="linear_equations",
        difficulty="easy",
        expected_time=30,
        hint="Restá 5 de ambos lados",
        answer="x = 4",
        generated_by="hardcoded_fallback"
    )


# ==================== LEGACY ENDPOINTS (mantener compatibilidad) ====================


@app.post("/api/solve", response_model=MathSolutionResponse)
async def solve_math(request: SolveMathRequest):
    """
    Resuelve una expresión matemática con pasos detallados.
    Endpoint legacy para compatibilidad con versiones anteriores.
    """
    try:
        if not request.expression.strip():
            raise HTTPException(status_code=400, detail="Expresión vacía")
        
        print(f"📥 Resolviendo: {request.expression}")
        
        solution = MathSolver.solve_with_steps(request.expression)
        
        # Convertir steps
        steps = [
            MathStepResponse(
                step_number=step["step_number"],
                expression=step["expression"],
                explanation=step["explanation"],
                latex=step.get("latex")
            )
            for step in solution["steps"]
        ]
        
        result = MathSolutionResponse(
            expression=request.expression,
            solution=solution["solution"],
            steps=steps,
            hints=solution["hints"],
            latex_steps=solution.get("latex_steps"),
            graph_data=solution.get("graph_data")
        )
        
        print(f"✅ Solución: {result.solution}")
        
        if result.graph_data:
            print(f"📊 graph_data incluido: can_graph={result.graph_data.get('can_graph')}")
        
        return result
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error al resolver: {str(e)}")


@app.post("/api/hints")
async def get_hints(request: dict):
    """Obtiene pistas progresivas para una expresión"""
    try:
        expression = request.get("expression", "")
        level = request.get("level", 0)
        
        if not expression:
            raise HTTPException(status_code=400, detail="Expression required")
        
        hints = MathSolver.get_hints(expression, level)
        
        return {
            "expression": expression,
            "hints": hints,
            "level": level
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/topics")
async def get_topics():
    """Lista de temas disponibles con ejemplos"""
    return {
        "topics": [
            {
                "id": "arithmetic",
                "name": "Aritmética",
                "examples": ["2 + 3", "10 - 5", "4 * 6", "20 / 5"]
            },
            {
                "id": "linear_equations",
                "name": "Ecuaciones Lineales",
                "examples": ["2x + 5 = 13", "x + 2 = 5", "3x - 1 = 8"]
            },
            {
                "id": "algebra",
                "name": "Álgebra",
                "examples": ["2 * (3 + 4)", "2^3", "sqrt(16)"]
            },
            {
                "id": "quadratic_equations",
                "name": "Ecuaciones Cuadráticas",
                "examples": ["x^2 - 4 = 0", "2x^2 + 3x - 5 = 0"]
            },
            {
                "id": "fractions",
                "name": "Fracciones",
                "examples": ["1/2 + 1/4", "3/4 * 2/3", "5/6 / 1/3"]
            }
        ]
    }


# ==================== ERROR HANDLERS ====================


from fastapi.responses import JSONResponse

@app.exception_handler(404)
async def not_found_handler(request, exc):
    return JSONResponse(
        status_code=404,
        content={
            "error": "Not Found",
            "message": f"Endpoint {request.url.path} no existe",
            "available_endpoints": [
                "/",
                "/health",
                "/docs",
                "/api/solve",
                "/api/hints",
                "/api/topics",
                "/api/problem/generate/adaptive"
            ]
        }
    )


@app.exception_handler(500)
async def internal_error_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error",
            "message": "Error interno del servidor",
            "details": str(exc)
        }
    )


# ==================== RUN SERVER ====================


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,  # Auto-reload en desarrollo
        log_level="info"
    )
