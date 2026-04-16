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


class GuidedExerciseRequest(BaseModel):
    user_id: str
    topic_id: str
    tutorial_equation: Optional[str] = None

class GuidedBlock(BaseModel):
    id: str
    value: str
    type: str # blockGreen, blockDark, operator
    side: str # left, center, right

class GuidedStep(BaseModel):
    instruction: str
    tts_text: str
    target_block_id: Optional[str] = None
    expected_side: Optional[str] = None
    blocks_before: Optional[List[GuidedBlock]] = []
    blocks_after: List[GuidedBlock]
    success_message: str
    error_message: str
    bunny_action: str = "talk"

class GuidedExerciseResponse(BaseModel):
    equation: str
    answer: str
    steps: List[GuidedStep]


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
                "examples": ["x^2-4=0", "2x^2+3=11"]
            },
            {
                "id": "cubic_equations",
                "name": "Ecuaciones Cúbicas",
                "examples": ["x^3=8", "2x^3=16"]
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

# ==================== ENDPOINT: GUIDED EXERCISE ====================

def _coef_str(a: int) -> str:
    """Retorna el string del coeficiente: '' si es 1, '-' si es -1, str(a) si otro."""
    if a == 1:
        return ""
    if a == -1:
        return "-"
    return str(a)

import random
import re

def _generate_similar_equation(tutorial_eq: str) -> str:
    """
    Detecta la estructura de la ecuación del tutorial y genera
    una variante con coeficientes aleatorios distintos.
    """
    eq = tutorial_eq.replace(" ", "").replace("²", "^2").replace("³", "^3")
    
    # Cuadrática: Ax^2 + B = C  o  x^2 = C
    m = re.match(r'^(-?\d*)x[\^]2([+-]\d+)?=(-?\d+)$', eq)
    if m:
        orig_a_str = m.group(1)
        orig_b_str = m.group(2)
        
        # Si la ecuación original tiene coeficiente (!= 1, != ""), forzar que la nueva lo tenga
        if orig_a_str not in ('', '1', '-1'):
            a = random.choice([2, 3, 4]) if orig_a_str != '-' else -random.choice([2, 3, 4])
        else:
            a = 1 if orig_a_str != '-' else -1
            
        # Si la ecuación original tiene un término sumando, forzar que la nueva lo tenga
        if orig_b_str:
            b = random.randint(1, 6) * random.choice([1, -1])
        else:
            b = 0
            
        # garantizar raíz entera
        base = random.choice([2, 3, 4, 5])
        c = a * base**2 + b
        a_str = "" if a == 1 else ("-" if a == -1 else str(a))
        b_str = f"+{b}" if b > 0 else (str(b) if b < 0 else "")
        return f"{a_str}x^2{b_str}={c}"
    
    # Cúbica: Ax^3 + B = C o Ax^3 = C
    m = re.match(r'^(-?\d*)x[\^]3([+-]\d+)?=(-?\d+)$', eq)
    if m:
        orig_a_str = m.group(1)
        orig_b_str = m.group(2)
        
        # Si la original tiene coeficiente
        if orig_a_str not in ('', '1', '-1'):
            a = random.choice([2, 3]) if orig_a_str != '-' else -random.choice([2, 3])
        else:
            a = 1 if orig_a_str != '-' else -1
            
        # Si la original tiene sumando
        if orig_b_str:
            b = random.randint(1, 6) * random.choice([1, -1])
        else:
            b = 0
            
        base = random.choice([2, 3])
        c = a * base**3 + b
        a_str = "" if a == 1 else ("-" if a == -1 else str(a))
        b_str = f"+{b}" if b > 0 else (str(b) if b < 0 else "")
        return f"{a_str}x^3{b_str}={c}"
    
    # Distributiva: A(x+B)=C
    m = re.match(r'^(-?\d+)\(x([+-]\d+)\)=(-?\d+)$', eq)
    if m:
        a = random.randint(2, 5)
        b = random.randint(1, 5) * random.choice([-1, 1])
        x = random.randint(1, 8)
        c = a * (x + b)
        sign = "+" if b >= 0 else ""
        return f"{a}(x{sign}{b})={c}"
    
    # Factorización: Ax^2 + Bx = 0  (A puede ser 1 o cualquier entero positivo)
    m = re.match(r'^(-?\d*)x[\^]2([+-]\d+)x=0$', eq)
    if m:
        a = random.randint(1, 4)
        b = random.randint(2, 7) * random.choice([-1, 1])
        a_str = "" if a == 1 else str(a)
        sign = "+" if b >= 0 else ""
        return f"{a_str}x^2{sign}{b}x=0"
    
    # Lineal completa: Ax + B = C
    m = re.match(r'^(-?\d*)x([+-]\d+)=(-?\d+)$', eq)
    if m:
        a = random.randint(2, 5)
        b = random.randint(1, 8) * random.choice([-1, 1])
        x = random.randint(1, 6)
        c = a * x + b
        sign = "+" if b >= 0 else ""
        return f"{a}x{sign}{b}={c}"
    
    # Lineal simple: Ax = C
    m = re.match(r'^(-?\d*)x=(-?\d+)$', eq)
    if m:
        a = random.randint(2, 6)
        x = random.randint(1, 9)
        return f"{a}x={a*x}"
    
    # Fallback: usar la misma ecuación original
    return tutorial_eq

@router.post("/guided-exercise/generate", response_model=GuidedExerciseResponse)
async def generate_guided_exercise(request: GuidedExerciseRequest):
    """
    ⭐ Genera ejercicio guiado con bloques INICIALES y FINALES de cada paso.
    Soporta: lineal (Ax+B=C, Ax=C), cuadrática (Ax^2+B=C), cúbica (Ax^3=C),
    distributiva (A(x+B)=C) y factorización básica (x^2+Bx=0).
    """
    import math
    import re

    raw_eq = (request.tutorial_equation or "3x + 6 = 21").strip().replace("²", "^2").replace("³", "^3")
    equation = _generate_similar_equation(raw_eq)
    eq_clean = equation.replace(" ", "")

    # ─── Helpers ───────────────────────────────────────────────────────────────
    def lin_blocks(a, b, c, show_b=True):
        """Bloques que representan Ax + B = C (usados como blocks_before del primer paso)."""
        a_str_val = _coef_str(a)
        blks = []
        idx = 1
        if a_str_val:
            blks.append({"id": f"left_{idx}", "value": a_str_val, "type": "blockGreen", "side": "left"})
            idx += 1
        blks.append({"id": f"left_{idx}", "value": "x", "type": "blockDark", "side": "left"})
        idx += 1
        if show_b and b != 0:
            sign = "+" if b > 0 else "-"
            blks.append({"id": f"left_{idx}", "value": f"{sign}{abs(b)}", "type": "blockGreen", "side": "left"})
            idx += 1
        blks.append({"id": "eq", "value": "=", "type": "operator", "side": "center"})
        blks.append({"id": "right_1", "value": str(c), "type": "blockGreen", "side": "right"})
        return blks

    def ax_blocks(a, var_label, c):
        """Bloques Ax^p = c (sin B) o solo x^p = c."""
        blks = []
        a_str_val = _coef_str(a)
        if a_str_val:
            blks.append({"id": "left_1", "value": a_str_val, "type": "blockGreen", "side": "left"})
        blks.append({"id": "left_2", "value": var_label, "type": "blockDark", "side": "left"})
        blks.append({"id": "eq", "value": "=", "type": "operator", "side": "center"})
        blks.append({"id": "right_1", "value": str(c), "type": "blockGreen", "side": "right"})
        return blks

    # ─── LINEAL: Ax + B = C  |  Ax = C  |  x + B = C ──────────────────────────
    m = re.match(r'^(-?\d*)x([+-]\d+)?=(-?\d+)$', eq_clean)
    if m:
        a_str, b_str, c_str = m.groups()
        a = int(a_str) if a_str not in ('', '-', None) else (-1 if a_str == '-' else 1)
        b = int(b_str) if b_str else 0
        c = int(c_str)
        c_next = c - b
        a_final = c_next // a if a != 0 else c_next

        # Bloques iniciales de toda la ecuación
        initial_blocks = lin_blocks(a, b, c)

        steps = []

        if b != 0:
            sign_b = "+" if b > 0 else "-"
            abs_b = abs(b)
            # blocks_before: ecuación completa
            # blocks_after: sin el término B
            coef_id = "left_1" if _coef_str(a) else None
            target_id = "left_3" if coef_id else "left_2"

            blocks_before_step1 = lin_blocks(a, b, c)
            blocks_after_step1 = []
            if _coef_str(a):
                blocks_after_step1.append({"id": "left_1", "value": _coef_str(a), "type": "blockGreen", "side": "left"})
            blocks_after_step1.append({"id": "left_2", "value": "x", "type": "blockDark", "side": "left"})
            blocks_after_step1.append({"id": "eq", "value": "=", "type": "operator", "side": "center"})
            blocks_after_step1.append({"id": "right_1", "value": str(c_next), "type": "blockGreen", "side": "right"})

            steps.append({
                "instruction": f"Pasa el {sign_b}{abs_b} al otro lado. ¡Cambia el signo!",
                "tts_text": f"Arrastra el {sign_b}{abs_b} al lado derecho. Cuando cruza el igual, su signo cambia.",
                "target_block_id": target_id,
                "expected_side": "right",
                "success_message": "¡Exacto! El signo cambió al cruzar el igual.",
                "error_message": f"Ese no es. Arrastra el {sign_b}{abs_b}.",
                "bunny_action": "celebrate",
                "blocks_before": blocks_before_step1,
                "blocks_after": blocks_after_step1,
            })

        if a not in (1, 0, -1):
            blocks_before_step2 = []
            if _coef_str(a):
                blocks_before_step2.append({"id": "left_1", "value": _coef_str(a), "type": "blockGreen", "side": "left"})
            blocks_before_step2.append({"id": "left_2", "value": "x", "type": "blockDark", "side": "left"})
            blocks_before_step2.append({"id": "eq", "value": "=", "type": "operator", "side": "center"})
            blocks_before_step2.append({"id": "right_1", "value": str(c_next), "type": "blockGreen", "side": "right"})

            steps.append({
                "instruction": f"Divide ambos lados por {a}.",
                "tts_text": f"El {a} multiplica a la x. Pásalo dividiendo al otro lado.",
                "target_block_id": "left_1",
                "expected_side": "right",
                "success_message": "¡Perfecto! Despejaste la x.",
                "error_message": f"Arrastra el {a} al otro lado.",
                "bunny_action": "celebrate",
                "blocks_before": blocks_before_step2,
                "blocks_after": [
                    {"id": "left_2", "value": "x", "type": "blockDark", "side": "left"},
                    {"id": "eq", "value": "=", "type": "operator", "side": "center"},
                    {"id": "right_1", "value": str(a_final), "type": "blockGreen", "side": "right"},
                ],
            })

        if not steps:
            # Ecuación ya resuelta o a=1, b=0
            steps.append({
                "instruction": "x ya está despejada. Verifica la solución.",
                "tts_text": "Esta ecuación ya tiene la x despejada.",
                "target_block_id": None,
                "expected_side": "right",
                "success_message": "¡Genial!",
                "error_message": "Listo.",
                "bunny_action": "celebrate",
                "blocks_before": lin_blocks(a, b, c),
                "blocks_after": [
                    {"id": "left_2", "value": "x", "type": "blockDark", "side": "left"},
                    {"id": "eq", "value": "=", "type": "operator", "side": "center"},
                    {"id": "right_1", "value": str(c), "type": "blockGreen", "side": "right"},
                ],
            })

        return GuidedExerciseResponse(equation=equation, answer=f"x = {a_final}", steps=steps)

    # ─── CUADRÁTICA / CÚBICA: Ax^P + B = C ─────────────────────────────────────
    m = re.match(r'^(-?\d*)x\^(\d+)([+-]\d+)?=(-?\d+)$', eq_clean) or \
        re.match(r'^(-?\d*)x\*\*(\d+)([+-]\d+)?=(-?\d+)$', eq_clean)
    if m:
        a_str, p_str, b_str, c_str = m.groups()
        a = int(a_str) if a_str not in ('', '-', None) else (-1 if a_str == '-' else 1)
        power = int(p_str)
        b = int(b_str) if b_str else 0
        c = int(c_str)
        c_next = c - b
        c_div = c_next // a if a != 0 else c_next

        var_label = f"x^{power}"

        # Calcular respuesta
        if power == 2:
            root_val = int(math.sqrt(abs(c_div))) if c_div >= 0 else None
            ans_str = f"±{root_val}" if root_val is not None else "sin solución real"
        elif power == 3:
            root_val = int(round(c_div ** (1.0 / 3))) if c_div >= 0 else -int(round(abs(c_div) ** (1.0 / 3)))
            ans_str = str(root_val)
        else:
            ans_str = "?"

        tipo_raiz = "cuadrada" if power == 2 else "cúbica"

        # Bloques iniciales: A·x^P + B = C
        def pow_initial():
            blks = []
            idx = 1
            if _coef_str(a):
                blks.append({"id": f"left_{idx}", "value": _coef_str(a), "type": "blockGreen", "side": "left"})
                idx += 1
            blks.append({"id": f"left_{idx}", "value": var_label, "type": "blockDark", "side": "left"})
            idx += 1
            if b != 0:
                sign = "+" if b > 0 else "-"
                blks.append({"id": f"left_{idx}", "value": f"{sign}{abs(b)}", "type": "blockGreen", "side": "left"})
            blks.append({"id": "eq", "value": "=", "type": "operator", "side": "center"})
            blks.append({"id": "right_1", "value": str(c), "type": "blockGreen", "side": "right"})
            return blks

        steps = []

        if b != 0:
            sign_b = "+" if b > 0 else "-"
            target_b_id = "left_3" if _coef_str(a) else "left_2"

            blks_after_b = []
            if _coef_str(a):
                blks_after_b.append({"id": "left_1", "value": _coef_str(a), "type": "blockGreen", "side": "left"})
            blks_after_b.append({"id": "left_2", "value": var_label, "type": "blockDark", "side": "left"})
            blks_after_b.append({"id": "eq", "value": "=", "type": "operator", "side": "center"})
            blks_after_b.append({"id": "right_1", "value": str(c_next), "type": "blockGreen", "side": "right"})

            steps.append({
                "instruction": f"Pasa el {sign_b}{abs(b)} al otro lado.",
                "tts_text": f"Arrastra el {sign_b}{abs(b)} al lado derecho para aislar la potencia.",
                "target_block_id": target_b_id,
                "expected_side": "right",
                "success_message": "¡Así se hace!",
                "error_message": f"Arrastra el término {sign_b}{abs(b)}.",
                "bunny_action": "think",
                "blocks_before": pow_initial(),
                "blocks_after": blks_after_b,
            })

        if a not in (1, 0, -1):
            blks_before_a = []
            if _coef_str(a):
                blks_before_a.append({"id": "left_1", "value": _coef_str(a), "type": "blockGreen", "side": "left"})
            blks_before_a.append({"id": "left_2", "value": var_label, "type": "blockDark", "side": "left"})
            blks_before_a.append({"id": "eq", "value": "=", "type": "operator", "side": "center"})
            blks_before_a.append({"id": "right_1", "value": str(c_next), "type": "blockGreen", "side": "right"})

            steps.append({
                "instruction": f"Divide por {a}.",
                "tts_text": f"Pasa el {a} dividiendo al otro lado.",
                "target_block_id": "left_1",
                "expected_side": "right",
                "success_message": "¡Genial!",
                "error_message": f"Arrastra el {a}.",
                "bunny_action": "think",
                "blocks_before": blks_before_a,
                "blocks_after": [
                    {"id": "left_2", "value": var_label, "type": "blockDark", "side": "left"},
                    {"id": "eq", "value": "=", "type": "operator", "side": "center"},
                    {"id": "right_1", "value": str(c_div), "type": "blockGreen", "side": "right"},
                ],
            })

        # Paso raíz
        blks_before_root = [
            {"id": "left_2", "value": var_label, "type": "blockDark", "side": "left"},
            {"id": "eq", "value": "=", "type": "operator", "side": "center"},
            {"id": "right_1", "value": str(c_div), "type": "blockGreen", "side": "right"},
        ]
        steps.append({
            "instruction": f"Aplica la raíz {tipo_raiz} para despejar x.",
            "tts_text": f"Arrastra el exponente fuera. Se aplica la raíz {tipo_raiz} a ambos lados.",
            "target_block_id": "left_2",
            "expected_side": "right",
            "success_message": f"¡Ecuación {'cuadrática' if power == 2 else 'cúbica'} resuelta!",
            "error_message": f"Arrastra la {var_label}.",
            "bunny_action": "celebrate",
            "blocks_before": blks_before_root if steps else pow_initial(),
            "blocks_after": [
                {"id": "left_2", "value": "x", "type": "blockDark", "side": "left"},
                {"id": "eq", "value": "=", "type": "operator", "side": "center"},
                {"id": "right_1", "value": ans_str, "type": "blockGreen", "side": "right"},
            ],
        })

        return GuidedExerciseResponse(equation=equation, answer=f"x = {ans_str}", steps=steps)

    # ─── DISTRIBUTIVA: A(x + B) = C ─────────────────────────────────────────────
    m = re.match(r'^(-?\d+)\(x([+-]\d+)\)=(-?\d+)$', eq_clean)
    if m:
        a_str, b_str, c_str = m.groups()
        a = int(a_str)
        b = int(b_str)
        c = int(c_str)
        c_div = c // a
        x_final = c_div - b
        sign_b = "+" if b > 0 else "-"

        initial_blocks = [
            {"id": "left_1", "value": str(a), "type": "blockGreen", "side": "left"},
            {"id": "left_2", "value": "(x", "type": "blockDark", "side": "left"},
            {"id": "left_3", "value": f"{sign_b}{abs(b)})", "type": "blockGreen", "side": "left"},
            {"id": "eq", "value": "=", "type": "operator", "side": "center"},
            {"id": "right_1", "value": str(c), "type": "blockGreen", "side": "right"},
        ]

        expand_blocks = [
            {"id": "left_1", "value": str(a * 1), "type": "blockDark", "side": "left"},
            {"id": "left_2", "value": "x", "type": "blockDark", "side": "left"},
            {"id": "left_3", "value": f"{'+' if a*b>0 else '-'}{abs(a*b)}", "type": "blockGreen", "side": "left"},
            {"id": "eq", "value": "=", "type": "operator", "side": "center"},
            {"id": "right_1", "value": str(c), "type": "blockGreen", "side": "right"},
        ]

        return GuidedExerciseResponse(
            equation=equation,
            answer=f"x = {x_final}",
            steps=[
                {
                    "instruction": f"Distribuye el {a}. Multiplica {a}·x y {a}·({sign_b}{abs(b)}).",
                    "tts_text": f"Arrastra el {a} para distribuirlo dentro del paréntesis.",
                    "target_block_id": "left_1",
                    "expected_side": "right",
                    "success_message": "¡Distribución correcta!",
                    "error_message": f"Arrastra el {a}.",
                    "bunny_action": "think",
                    "blocks_before": initial_blocks,
                    "blocks_after": expand_blocks,
                },
                {
                    "instruction": f"Pasa el {'+' if a*b>0 else '-'}{abs(a*b)} al otro lado.",
                    "tts_text": f"Arrastra el término independiente al lado derecho.",
                    "target_block_id": "left_3",
                    "expected_side": "right",
                    "success_message": "¡Perfecto!",
                    "error_message": "Arrastra el término numérico.",
                    "bunny_action": "celebrate",
                    "blocks_before": expand_blocks,
                    "blocks_after": [
                        {"id": "left_1", "value": str(a), "type": "blockGreen", "side": "left"},
                        {"id": "left_2", "value": "x", "type": "blockDark", "side": "left"},
                        {"id": "eq", "value": "=", "type": "operator", "side": "center"},
                        {"id": "right_1", "value": str(c - a * b), "type": "blockGreen", "side": "right"},
                    ],
                },
                {
                    "instruction": f"Divide por {a}.",
                    "tts_text": f"Pasa el {a} al otro lado dividiendo.",
                    "target_block_id": "left_1",
                    "expected_side": "right",
                    "success_message": "¡Ecuación resuelta!",
                    "error_message": f"Arrastra el {a}.",
                    "bunny_action": "celebrate",
                    "blocks_before": [
                        {"id": "left_1", "value": str(a), "type": "blockGreen", "side": "left"},
                        {"id": "left_2", "value": "x", "type": "blockDark", "side": "left"},
                        {"id": "eq", "value": "=", "type": "operator", "side": "center"},
                        {"id": "right_1", "value": str(c - a * b), "type": "blockGreen", "side": "right"},
                    ],
                    "blocks_after": [
                        {"id": "left_2", "value": "x", "type": "blockDark", "side": "left"},
                        {"id": "eq", "value": "=", "type": "operator", "side": "center"},
                        {"id": "right_1", "value": str(x_final), "type": "blockGreen", "side": "right"},
                    ],
                },
            ],
        )

    # ─── FACTORIZACIÓN: Ax^2 + Bx = 0 ──────────────────────────────────────────
    m = re.match(r'^(-?\d*)x\^2([+-]\d+)x=0$', eq_clean)
    if m:
        a_str_f, b_str = m.groups()
        a_f = int(a_str_f) if a_str_f not in ('', '-', None) else (-1 if a_str_f == '-' else 1)
        b = int(b_str)
        sign_b = "+" if b > 0 else "-"

        # Para factorizacion: raiz no nula es -b/a_f
        simplified_b = b // a_f if a_f not in (0, 1) else b
        root_nonzero = -simplified_b
        a_f_str = "" if a_f == 1 else str(a_f)
        sign_sb = "+" if simplified_b > 0 else "-"

        # Bloques iniciales con coeficiente A si existe
        initial_blocks = []
        if a_f_str:
            initial_blocks.append({"id": "left_1", "value": a_f_str, "type": "blockGreen", "side": "left"})
        initial_blocks.append({"id": "left_2", "value": "x^2", "type": "blockDark", "side": "left"})
        initial_blocks.append({"id": "left_3", "value": f"{sign_b}{abs(b)}x", "type": "blockGreen", "side": "left"})
        initial_blocks.append({"id": "eq", "value": "=", "type": "operator", "side": "center"})
        initial_blocks.append({"id": "right_1", "value": "0", "type": "blockGreen", "side": "right"})

        steps = []
        # Paso opcional: dividir por A si A != 1
        if a_f not in (0, 1):
            simplified_after = [
                {"id": "left_2", "value": "x^2", "type": "blockDark", "side": "left"},
                {"id": "left_3", "value": f"{'+' if simplified_b > 0 else ''}{simplified_b}x", "type": "blockGreen", "side": "left"},
                {"id": "eq", "value": "=", "type": "operator", "side": "center"},
                {"id": "right_1", "value": "0", "type": "blockGreen", "side": "right"},
            ]
            steps.append({
                "instruction": f"Divide todo por {a_f} para simplificar.",
                "tts_text": f"Divide ambos lados por {a_f} para que el coeficiente de x² sea 1.",
                "target_block_id": "left_1",
                "expected_side": "right",
                "success_message": "¡Bien! Ahora es más fácil factorizar.",
                "error_message": f"Arrastra el {a_f_str} al otro lado.",
                "bunny_action": "think",
                "blocks_before": initial_blocks,
                "blocks_after": simplified_after,
            })
            blocks_for_factor = simplified_after
        else:
            blocks_for_factor = initial_blocks

        # Paso factorizar
        steps.append({
            "instruction": f"Factoriza: x(x {sign_sb} {abs(simplified_b)}) = 0",
            "tts_text": "Saca x como factor común. Arrastra el x² para factorizarlo.",
            "target_block_id": "left_2",
            "expected_side": "right",
            "success_message": "¡Factorización correcta!",
            "error_message": "Arrastra el x² para factorizar.",
            "bunny_action": "think",
            "blocks_before": blocks_for_factor,
            "blocks_after": [
                {"id": "left_1", "value": "x", "type": "blockDark", "side": "left"},
                {"id": "left_2", "value": f"(x{sign_sb}{abs(simplified_b)})", "type": "blockGreen", "side": "left"},
                {"id": "eq", "value": "=", "type": "operator", "side": "center"},
                {"id": "right_1", "value": "0", "type": "blockGreen", "side": "right"},
            ],
        })
        # Paso soluciones
        steps.append({
            "instruction": f"Las soluciones son x=0 y x={root_nonzero}.",
            "tts_text": f"Si el producto es 0, uno de los factores es 0. Por lo tanto x=0 o x={root_nonzero}.",
            "target_block_id": None,
            "expected_side": "right",
            "success_message": "¡Ecuación factorizada y resuelta!",
            "error_message": "Listo.",
            "bunny_action": "celebrate",
            "blocks_before": [
                {"id": "left_1", "value": "x", "type": "blockDark", "side": "left"},
                {"id": "left_2", "value": f"(x{sign_sb}{abs(simplified_b)})", "type": "blockGreen", "side": "left"},
                {"id": "eq", "value": "=", "type": "operator", "side": "center"},
                {"id": "right_1", "value": "0", "type": "blockGreen", "side": "right"},
            ],
            "blocks_after": [
                {"id": "left_1", "value": "x", "type": "blockDark", "side": "left"},
                {"id": "eq", "value": "=", "type": "operator", "side": "center"},
                {"id": "right_1", "value": f"0 ó {root_nonzero}", "type": "blockGreen", "side": "right"},
            ],
        })

        return GuidedExerciseResponse(equation=equation, answer=f"x = 0 o x = {root_nonzero}", steps=steps)

    # ─── FALLBACK ROBUSTO: parseo genérico ─────────────────────────────────────
    # Construir bloques básicos tokenizando el string de la ecuación original
    parts = equation.split("=")
    left_str = parts[0].strip() if len(parts) > 0 else "?"
    right_str = parts[1].strip() if len(parts) > 1 else "?"
    
    def tokenize_side(side_str, side_name):
        # Tokens: numbers (con signo o sin), variables, operadores, paréntesis
        # matches: +3, -4, 2, x, a, +, -, etc.
        # But we want "+b" as one block or "+" and "b" separated? 
        # The frontend supports numbers with signs. For variables, "a", "x", "+b".
        tokens = re.findall(r'[+-]?\d+|[+-]?[a-zA-Z]|[=+\-*/()]', side_str.replace(" ", ""))
        blocks = []
        for i, t in enumerate(tokens):
            if t in "+-*/" and len(t) == 1:
                btype = "operator"
            elif "x" in t or "y" in t or "(" in t:
                btype = "blockDark"
            else:
                btype = "blockGreen"
            blocks.append({
                "id": f"{side_name}_{i}",
                "value": t.replace("+", "+ "), # format slightly for UI
                "type": btype,
                "side": side_name
            })
        return blocks

    fallback_blocks_before = tokenize_side(left_str, "left") + [
        {"id": "eq", "value": "=", "type": "operator", "side": "center"}
    ] + tokenize_side(right_str, "right")
    return GuidedExerciseResponse(
        equation=equation,
        answer="x = ?",
        steps=[
            {
                "instruction": "Despeja x paso a paso.",
                "tts_text": "Resuelve esta ecuación arrastrando los bloques.",
                "target_block_id": "left_1",
                "expected_side": "right",
                "success_message": "¡Bien hecho!",
                "error_message": "Inténtalo de nuevo.",
                "bunny_action": "celebrate",
                "blocks_before": fallback_blocks_before,
                "blocks_after": [
                    {"id": "left_ans", "value": "x", "type": "blockDark", "side": "left"},
                    {"id": "eq", "value": "=", "type": "operator", "side": "center"},
                    {"id": "right_ans", "value": "?", "type": "blockGreen", "side": "right"},
                ],
            }
        ],
    )
