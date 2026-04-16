import sys
import os

# Añadir el path actual al sys.path para importar math_engine
sys.path.append(os.getcwd())

from api.equation_decomposer import _get_equation_type, _decompose_side

test_equations = [
    "x² + 5x + 6 = 0",
    "x³ = 27",
    "2(x + 3) = 14",
    "(x - 1)(x + 2) = 0",
    "4x - 2 = 10"
]

print("--- Verificando Tipos de Ecuación ---")
for eq in test_equations:
    eq_type = _get_equation_type(eq)
    print(f"Ecuación: {eq} -> Tipo: {eq_type}")

print("\n--- Verificando Tokenización (Lado Izquierdo) ---")
for eq in test_equations:
    left = eq.split('=')[0].strip()
    blocks = _decompose_side(left, "left")
    print(f"Lado: {left} -> Bloques: {[b['value'] for b in blocks]}")
