from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import re
from sympy import symbols, Eq, solve, sympify, simplify
from math_engine.solver import MathSolver

router = APIRouter(tags=["Decomposer"])

class DecomposeRequest(BaseModel):
    equation: str

class EquationBlock(BaseModel):
    id: str
    value: str
    type: str # blockGreen, blockDark, operator
    side: str # left, center, right

class DecomposeResponse(BaseModel):
    equation: str
    answer: str
    type: str
    blocks: List[EquationBlock]
    steps: Optional[List[Any]] = []

def _get_equation_type(eq_part: str) -> str:
    """Intenta deducir el tipo de ecuación para el frontend."""
    eq_clean = eq_part.replace(" ", "").replace("**", "^").replace("\u00b2", "^2").replace("\u00b3", "^3")
    
    # Detección de Factorizada: (x-1)(x+2)=0
    if ")(" in eq_clean:
        return "factored"
    
    # Detección de Distributiva: 2(x+3)=10
    if "(" in eq_clean and ")" in eq_clean:
        return "distributive"
        
    if "^3" in eq_clean:
        return "cubic"
    if "^2" in eq_clean:
        return "quadratic"
    return "linear"

def _decompose_side(side_str: str, side_label: str) -> List[Dict[str, str]]:
    """Descompone un lado de la ecuación en bloques."""
    blocks = []
    
    s = (
        side_str
        .replace(" ", "")
        .replace("**", "^")
        .replace("\u00b2", "^2")
        .replace("\u00b3", "^3")
    )
    
    # Tokenizar términos: sign? (coeff? (parens) | coeff? var (^exp)? | constantes)
    # Explicación regex actualizada: soportar decimales con . o ,
    # 1. [+-]?\d*(?:[\.,]\d+)?\(.*?\) -> Términos con paréntesis: 2,5(x+3)
    # 2. [+-]?\d*(?:[\.,]\d+)?[a-zA-Z](?:\^\d+)? -> Términos con variable: 1,5x^2
    # 3. [+-]?\d*(?:[\.,]\d+)? -> Constantes: 5.5, -10,2
    pattern = r'([+-]?\d*(?:[\.,]\d+)?\(.*?\)|[+-]?\d*(?:[\.,]\d+)?[a-zA-Z](?:\^\d+)?|[+-]?\d*(?:[\.,]\d+)?)'
    tokens = re.findall(pattern, s)
    
    for i, token in enumerate(tokens):
        if not token:
            continue
            
        # Determinar tipo
        if "(" in token:
            btype = "blockDark" # Paréntesis suelen ser términos complejos
        elif re.search(r'[a-zA-Z]', token):
            btype = "blockDark"
        else:
            btype = "blockGreen"
            
        blocks.append({
            "id": f"{side_label}_{i}",
            "value": token,
            "type": btype,
            "side": side_label
        })
            
    return blocks

@router.post("/equation/decompose", response_model=DecomposeResponse)
async def decompose_equation(request: DecomposeRequest):
    try:
        raw_eq = request.equation.strip()
        normalized_eq = MathSolver.normalize_expression(raw_eq)
        
        if "=" not in normalized_eq:
            raise HTTPException(status_code=400, detail="Falta el signo '='")
            
        parts = normalized_eq.split('=')
        left_side_raw = parts[0].strip()
        right_side_raw = parts[1].strip()
        
        x = symbols('x')
        try:
            sol = solve(Eq(sympify(left_side_raw), sympify(right_side_raw)), x)
            if sol:
                answer_str = f"x = {str(sol[0])}"
            else:
                answer_str = "Sin solución"
        except Exception:
            answer_str = "Error al resolver"
            
        visual_parts = raw_eq.replace(" ", "").split('=')
        left_visual = visual_parts[0]
        right_visual = visual_parts[1]
        
        all_blocks = []
        all_blocks.extend(_decompose_side(left_visual, "left"))
        all_blocks.append({"id": "eq_operator", "value": "=", "type": "operator", "side": "center"})
        all_blocks.extend(_decompose_side(right_visual, "right"))
        
        eq_type = _get_equation_type(raw_eq)
        
        return DecomposeResponse(
            equation=raw_eq,
            answer=answer_str,
            type=eq_type,
            blocks=all_blocks,
            steps=[]
        )
        
    except Exception as e:
        print(f"❌ Decompose error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
