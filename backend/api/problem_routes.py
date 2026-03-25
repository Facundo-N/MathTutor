# backend/api/problem_routes.py
"""
Rutas para generación de problemas matemáticos
- /api/problem/generate/check → Verificar disponibilidad de OpenAI
- /api/problem/generate/adaptive → Generar con IA (OpenAI)
- /api/problem/generate/legacy → Generar sin IA (random)
"""

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Dict, Any, Optional
from pydantic import BaseModel
import os
from dotenv import load_dotenv

from math_engine.generator import ProblemGenerator
from math_engine.solver import MathSolver
from database.session import get_db

# Cargar variables de entorno
load_dotenv()

router = APIRouter(prefix="/api/problem", tags=["Problems"])


# ==================== MODELOS ====================

class GenerateAdaptiveProblemRequest(BaseModel):
    user_id: str
    topic: str = "linear_equations"
    difficulty: str = "medium"


class GenerateLegacyProblemRequest(BaseModel):
    topic: str = "linear_equations"
    difficulty: str = "medium"


class AdaptiveProblemResponse(BaseModel):
    expression: str
    topic: str
    difficulty: str
    expected_time: int
    hint: Optional[str] = None
    answer: str
    generated_by: str


class CheckAIAvailabilityResponse(BaseModel):
    available: bool
    provider: str
    model: Optional[str] = None
    reason: Optional[str] = None


# ==================== ENDPOINT: CHECK OPENAI AVAILABILITY ====================

@router.get("/generate/check", response_model=CheckAIAvailabilityResponse)
async def check_ai_availability():
    """
    ✅ Verifica si OpenAI está disponible
    
    Response:
    - Si OpenAI está configurado: {"available": true, "provider": "openai", "model": "gpt-4o-mini"}
    - Si no: {"available": false, "provider": "legacy", "reason": "..."}
    """
    
    print("🔍 Verificando disponibilidad de OpenAI...")
    
    # 1. Verificar que OPENAI_API_KEY esté configurado
    api_key = os.getenv('OPENAI_API_KEY')
    
    if not api_key:
        print("❌ OPENAI_API_KEY no configurado")
        return CheckAIAvailabilityResponse(
            available=False,
            provider="legacy",
            reason="OPENAI_API_KEY not configured in .env"
        )
    
    # 2. Verificar que openai esté instalado
    try:
        from openai import OpenAI
    except ImportError:
        print("❌ openai no está instalado")
        return CheckAIAvailabilityResponse(
            available=False,
            provider="legacy",
            reason="openai module not installed. Run: pip install openai"
        )
    
    # 3. Verificar que podamos instanciar el cliente
    try:
        client = OpenAI(api_key=api_key)
        # No hacemos llamada real (requeriría créditos), solo verificamos instanciación
        print("✅ OpenAI cliente instanciado correctamente")
        
        return CheckAIAvailabilityResponse(
            available=True,
            provider="openai",
            model="gpt-4o-mini",
            reason=None
        )
    except Exception as e:
        print(f"❌ Error inicializando OpenAI cliente: {e}")
        return CheckAIAvailabilityResponse(
            available=False,
            provider="legacy",
            reason=f"Failed to initialize OpenAI client: {str(e)}"
        )


# ==================== ENDPOINT: GENERAR CON IA ====================

@router.post("/generate/adaptive", response_model=AdaptiveProblemResponse)
async def generate_adaptive_problem(
    request: GenerateAdaptiveProblemRequest,
    db: Session = Depends(get_db)
):
    """
    ⭐ Genera problema ADAPTATIVO usando OpenAI
    
    - Analiza historial del usuario
    - Ajusta dificultad según desempeño
    - Crea problemas personalizados
    """
    
    print(f"📝 Generando problema adaptativo para {request.user_id}")
    print(f"   Tema: {request.topic}, Dificultad: {request.difficulty}")
    
    # Verificar OpenAI disponible
    api_key = os.getenv('OPENAI_API_KEY')
    if not api_key:
        print("⚠️ OpenAI no disponible, usando fallback")
        return await generate_legacy_problem(
            GenerateLegacyProblemRequest(
                topic=request.topic,
                difficulty=request.difficulty
            )
        )
    
    try:
        # Importar generador de IA
        from ai.problem_generator_ai import AIProblemGenerator
        
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
        
        print(f"✅ Problema generado por OpenAI: {problem.get('expression', '')}")
        
        # 3. Convertir a formato de respuesta
        return AdaptiveProblemResponse(
            expression=problem.get("expression", ""),
            topic=problem.get("topic", request.topic),
            difficulty=problem.get("difficulty", request.difficulty),
            expected_time=int(problem.get("expected_time", 30)),
            hint=problem.get("hint"),
            answer=problem.get("answer", ""),
            generated_by="openai"
        )
        
    except Exception as e:
        print(f"❌ Error con OpenAI: {e}")
        print("⚠️ Fallback a generador legacy")
        
        # Fallback: usar generador sin IA
        return await generate_legacy_problem(
            GenerateLegacyProblemRequest(
                topic=request.topic,
                difficulty=request.difficulty
            )
        )


# ==================== ENDPOINT: GENERAR SIN IA (LEGACY) ====================

@router.post("/generate/legacy", response_model=AdaptiveProblemResponse)
async def generate_legacy_problem(
    request: GenerateLegacyProblemRequest,
    db: Session = Depends(get_db)
):
    """
    Genera problema usando generador LEGACY (random, sin IA)
    
    Endpoints:
    - POST /api/problem/generate/legacy
    - POST /api/problem/generate/adaptive (con fallback a legacy)
    """
    
    print(f"🎲 Generando problema legacy para {request.topic}/{request.difficulty}")
    
    try:
        # Usar ProblemGenerator (random)
        problems = ProblemGenerator.generate_by_topic(
            topic=request.topic,
            difficulty=request.difficulty,
            count=1
        )
        
        if not problems:
            raise ValueError(f"No problems generated for {request.topic}")
        
        problem = problems[0]
        
        print(f"✅ Problema legacy generado: {problem.get('expression', '')}")
        
        return AdaptiveProblemResponse(
            expression=problem.get("expression", ""),
            topic=problem.get("topic", request.topic),
            difficulty=problem.get("difficulty", request.difficulty),
            expected_time=30,
            hint="Aislá la variable moviendo términos",
            answer=problem.get("answer", ""),
            generated_by="legacy_random"
        )
        
    except Exception as e:
        print(f"❌ Error generando problema legacy: {e}")
        
        # Último recurso: problema hardcodeado
        print("⚠️ Problema hardcodeado de respaldo")
        return AdaptiveProblemResponse(
            expression="2x + 5 = 13",
            topic="linear_equations",
            difficulty="easy",
            expected_time=30,
            hint="Restá 5 de ambos lados, luego divide por 2",
            answer="x = 4",
            generated_by="hardcoded_fallback"
        )


# ==================== ENDPOINTS ORIGINALES (MANTENER COMPATIBILIDAD) ====================

class GenerateProblemRequest(BaseModel):
    topic: str
    difficulty: str
    count: int = 1


class MathProblem(BaseModel):
    id: str
    expression: str
    topic: str
    difficulty: str
    answer: str


class MathProblemResponse(BaseModel):
    problems: List[MathProblem]
    count: int
    topic: str
    difficulty: str


class SolveProblemRequest(BaseModel):
    expression: str


class MathStepResponse(BaseModel):
    step_number: int
    expression: str
    explanation: str


class MathSolution(BaseModel):
    expression: str
    solution: str
    steps: List[MathStepResponse]
    hints: List[str]


class HintRequest(BaseModel):
    expression: str
    current_step: int = 0


@router.post("/generate", response_model=MathProblemResponse)
async def generate_problem(
    request: GenerateProblemRequest,
    db: Session = Depends(get_db)
):
    """
    Genera problemas matemáticos según tema y dificultad (LEGACY).
    """
    try:
        problems = ProblemGenerator.generate_by_topic(
            topic=request.topic,
            difficulty=request.difficulty,
            count=request.count
        )
        
        return MathProblemResponse(
            problems=problems,
            count=len(problems),
            topic=request.topic,
            difficulty=request.difficulty
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating problems: {str(e)}")


@router.post("/solve", response_model=MathSolution)
async def solve_problem(
    request: SolveProblemRequest,
    db: Session = Depends(get_db)
):
    """
    Resuelve un problema con pasos detallados.
    """
    try:
        if not request.expression.strip():
            raise HTTPException(status_code=400, detail="Expression cannot be empty")
        
        solution = MathSolver.solve_with_steps(request.expression)
        
        return MathSolution(**solution)
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error solving: {str(e)}")


@router.post("/hints")
async def get_hints(
    request: HintRequest,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """
    Obtiene pistas progresivas para un problema.
    """
    try:
        hints = MathSolver.get_hints(request.expression, request.current_step)
        
        return {
            "expression": request.expression,
            "hints": hints,
            "level": request.current_step
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting hints: {str(e)}")


@router.get("/topics")
async def get_available_topics() -> Dict[str, Any]:
    """
    Lista de temas disponibles con ejemplos.
    """
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


class ValidarPasoRequest(BaseModel):
    ecuacion_actual: str
    accion_texto: str
    error_type: Optional[str] = None


class ValidarPasoResponse(BaseModel):
    valido: bool
    tipo_error: Optional[str] = None
    mensaje_ayuda: Optional[str] = None


@router.post("/validar-paso", response_model=ValidarPasoResponse)
async def validar_paso(
    request: ValidarPasoRequest,
    db: Session = Depends(get_db)
):
    """
    ⭐ MVP Hiperpersonalización: Valida un paso (Draft Inicial)
    Si provee error_type desde el front (múltiple choice), usa esa taxonomía.
    De lo contrario podría deducir con SymPy/OpenAI.
    """
    if request.error_type:
        error = request.error_type
        mensaje = "Revisa tu operación."
        
        # Micro-enciclopedia de antipatrones común
        if error == "traidor_signo":
            mensaje = "¡Cuidado con el Traidor del Signo! Recuerda que al cruzar el '=', el número cambia de bando y de signo (+ se hace -, - se hace +)."
        elif error == "orden_operaciones":
            mensaje = "El Orden Sagrado se ha roto: recuerda alejar primero las sumas/restas y dejar la multiplicación/división para el final."
        elif error == "operacion_inversa_incorrecta":
            mensaje = "¡Atención! La operación inversa de la suma es la resta, de la multiplicación la división (y viceversa)."
        elif error == "peras_con_manzanas":
            mensaje = "Peras con manzanas: No puedes sumar números solitarios con términos que tienen 'x' si están separados por el paréntesis o de distinta naturaleza."
        elif error == "omision_raiz_negativa":
            mensaje = "Has olvidado la mitad de la historia: al aplicar raíz cuadrada a una variable, recuerda que hay un resultado positivo y uno negativo (±)."
        elif error == "movimiento_invalido":
            mensaje = "Ese bloque no se puede mover así en este momento. Intenta otra estrategia."
        elif error == "expansion_innecesaria":
            mensaje = "No hace falta multiplicar todo. Si tienes grupos multiplicándose igual a 0, ¡aplica la propiedad del producto cero!"

        return ValidarPasoResponse(
            valido=False,
            tipo_error=error,
            mensaje_ayuda=mensaje
        )
    
    # Si no hay error_type, asumimos que es correcto o genérico (para cuando hagamos Drag&Drop libre)
    # Por ahora, simplemente devolver válido = True como placeholder
    return ValidarPasoResponse(
        valido=True,
        tipo_error=None,
        mensaje_ayuda="¡Paso válido! (Placeholder)"
    )


# ==================== FUNCIONES AUXILIARES ====================

def _get_user_history(user_id: str, db: Session) -> Dict:
    """
    Obtiene historial del usuario de PostgreSQL
    """
    try:
        from database.models import UserSignal
        
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
