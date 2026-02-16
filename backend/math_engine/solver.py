"""Motor de resolución matemática con SymPy"""
from sympy import symbols, Eq, solve, sympify, simplify, latex
from sympy.parsing.sympy_parser import parse_expr, standard_transformations, implicit_multiplication_application
from typing import List, Dict
import re
import numpy as np  # ✅ NUEVO


x = symbols('x')


class MathSolver:
    @staticmethod
    def normalize_expression(expression: str) -> str:
        """
        Normaliza expresiones matemáticas para que SymPy las entienda
        
        Ejemplos:
        - "2 x + 6 = 0" → "2*x + 6 = 0"
        - "2x + 3" → "2*x + 3"
        - "2+3" → "2+3" (sin cambios)
        - "x + 2 = 5" → "x + 2 = 5" (sin cambios)
        """
        expr = expression.strip()
        
        # 1. Reemplazar multiplicación implícita: "2 x" → "2*x"
        expr = re.sub(r'(\d+)\s+([a-zA-Z])', r'\1*\2', expr)
        
        # 2. Reemplazar multiplicación implícita sin espacio: "2x" → "2*x"
        expr = re.sub(r'(\d+)([a-zA-Z])', r'\1*\2', expr)
        
        # 3. Reemplazar multiplicación entre paréntesis: "2(x+3)" → "2*(x+3)"
        expr = re.sub(r'(\d+)\(', r'\1*(', expr)
        
        # 4. Reemplazar "^" por "**" para exponentes
        expr = expr.replace('^', '**')
        
        print(f"🔄 Normalizado: '{expression}' → '{expr}'")
        return expr
    
    @staticmethod
    def solve_with_steps(expression: str) -> Dict:
        try:
            # Normalizar primero
            expression = MathSolver.normalize_expression(expression)
            
            if '=' in expression:
                return MathSolver._solve_equation(expression)
            else:
                return MathSolver._solve_expression(expression)
        except Exception as e:
            return {
                "expression": expression,
                "solution": "Error",
                "steps": [{"step_number": 1, "expression": expression, "explanation": f"Error: {str(e)}", "latex": "Error"}],
                "hints": [f"Verifica que la expresión esté bien escrita. Error: {str(e)}"],
                "latex_steps": []
            }
    
    @staticmethod
    def _solve_equation(equation_str: str) -> Dict:
        try:
            parts = equation_str.split('=')
            if len(parts) != 2:
                raise ValueError("Debe haber un signo igual")
            
            transformations = (standard_transformations + (implicit_multiplication_application,))
            left_expr = parse_expr(parts[0].strip(), transformations=transformations)
            right_expr = parse_expr(parts[1].strip(), transformations=transformations)
            equation = Eq(left_expr, right_expr)
            solutions = solve(equation, x)
            
            if not solutions:
                return {
                    "expression": equation_str,
                    "solution": "Sin solución",
                    "steps": [
                        {"step_number": 1, "expression": equation_str, "explanation": "Ecuación original", "latex": str(equation)},
                        {"step_number": 2, "expression": "No tiene solución", "explanation": "Esta ecuación no tiene solución en los números reales", "latex": "\\text{Sin solución}"}
                    ],
                    "hints": ["Esta ecuación no tiene solución"],
                    "latex_steps": [str(equation), "\\text{Sin solución}"],
                    "graph_data": {"can_graph": False}  # ✅ NUEVO
                }
            
            # Construir pasos detallados
            steps = [
                {
                    "step_number": 1,
                    "expression": equation_str,
                    "explanation": "📝 Ecuación original",
                    "latex": str(equation)
                }
            ]
            
            # Si los lados son diferentes, mover todo a la izquierda
            if left_expr != right_expr:
                simplified = simplify(left_expr - right_expr)
                steps.append({
                    "step_number": 2,
                    "expression": f"{left_expr - right_expr} = 0",
                    "explanation": "➡️ Movemos todo al lado izquierdo (restamos el lado derecho de ambos lados)",
                    "latex": f"{latex(left_expr - right_expr)} = 0"
                })
                
                if simplified != left_expr - right_expr:
                    steps.append({
                        "step_number": 3,
                        "expression": f"{simplified} = 0",
                        "explanation": "🔄 Simplificamos la expresión",
                        "latex": f"{latex(simplified)} = 0"
                    })
            
            # Solución final
            solution_value = solutions[0]
            steps.append({
                "step_number": len(steps) + 1,
                "expression": f"x = {solution_value}",
                "explanation": f"✅ ¡Solución encontrada! x vale {solution_value}",
                "latex": f"x = {latex(solution_value)}"
            })
            
            hints = [
                "💡 Identifica qué operaciones hay en la ecuación",
                "💡 Opera de la misma forma en ambos lados para mantener la igualdad",
                "💡 Simplifica paso a paso hasta despejar x"
            ]
            
            # ✅ NUEVO: Generar datos para gráfico
            graph_data = MathSolver.generate_graph_points(equation_str, float(solution_value))
            
            return {
                "expression": equation_str,
                "solution": str(solution_value),
                "steps": steps,
                "hints": hints,
                "latex_steps": [step["latex"] for step in steps],
                "graph_data": graph_data  # ✅ NUEVO
            }
        except Exception as e:
            return {
                "expression": equation_str,
                "solution": "Error",
                "steps": [{"step_number": 1, "expression": equation_str, "explanation": f"❌ Error: {str(e)}", "latex": "Error"}],
                "hints": [f"Verifica la expresión. Error: {str(e)}"],
                "latex_steps": [],
                "graph_data": {"can_graph": False}  # ✅ NUEVO
            }
    
    @staticmethod
    def _solve_expression(expr_str: str) -> Dict:
        try:
            transformations = (standard_transformations + (implicit_multiplication_application,))
            expr = parse_expr(expr_str, transformations=transformations)
            result = expr.evalf()
            
            steps = [
                {
                    "step_number": 1,
                    "expression": expr_str,
                    "explanation": "📝 Expresión original",
                    "latex": latex(expr)
                },
                {
                    "step_number": 2,
                    "expression": str(result),
                    "explanation": f"✅ Resultado: {result}",
                    "latex": latex(result)
                }
            ]
            
            hints = [
                "💡 Recuerda el orden de operaciones: Paréntesis → Exponentes → Multiplicación/División → Suma/Resta",
                "💡 Resuelve primero lo que está dentro de paréntesis",
                "💡 Luego multiplica/divide de izquierda a derecha"
            ]
            
            return {
                "expression": expr_str,
                "solution": str(result),
                "steps": steps,
                "hints": hints,
                "latex_steps": [latex(expr), latex(result)],
                "graph_data": {"can_graph": False}  # ✅ NUEVO (expresiones sin x no se grafican)
            }
        except Exception as e:
            return {
                "expression": expr_str,
                "solution": "Error",
                "steps": [{"step_number": 1, "expression": expr_str, "explanation": f"❌ Error: {str(e)}", "latex": "Error"}],
                "hints": [f"Verifica la expresión. Error: {str(e)}"],
                "latex_steps": [],
                "graph_data": {"can_graph": False}  # ✅ NUEVO
            }
    
    @staticmethod
    def get_hints(expression: str, level: int = 0) -> List[str]:
        expression = MathSolver.normalize_expression(expression)
        
        if '=' in expression:
            hints = [
                "💡 Nivel 1: Identifica qué operaciones hay en la ecuación",
                "💡 Nivel 2: Opera de la misma forma en ambos lados",
                "💡 Nivel 3: Simplifica y despeja la variable"
            ]
        else:
            hints = [
                "💡 Nivel 1: Orden de operaciones (PEMDAS)",
                "💡 Nivel 2: Resuelve paréntesis primero",
                "💡 Nivel 3: Luego multiplicación y división"
            ]
        
        return hints[:level+1] if level < len(hints) else hints
    
    # ✅ NUEVO: Función para generar puntos del gráfico
    @staticmethod
    def generate_graph_points(expression: str, solution_x: float = None) -> Dict:
        """
        Genera puntos para graficar una ecuación
        
        Args:
            expression: Ecuación original (ej: "2*x + 5 = 13" o "y = 2*x + 3")
            solution_x: Valor de x de la solución (para marcar en el gráfico)
        
        Returns:
            Dict con puntos x, y y metadatos del gráfico
        """
        print(f"📊 Intentando generar gráfico para: {expression}, solución x={solution_x}")  # ✅ DEBUG
        
        try:
            print("✅ NumPy disponible")  # ✅ DEBUG
            
            # Detectar si es ecuación con y (y = ...) o sin y (2x + 5 = 13)
            if 'y' in expression.lower():
                # Ecuación explícita: y = 2x + 3
                parts = expression.split('=')
                if len(parts) == 2 and 'y' in parts[0].lower():
                    expr_str = parts[1].strip()
                else:
                    expr_str = parts[0].strip()
            else:
                # Ecuación implícita: convertir 2x + 5 = 13 → y = 2x + 5
                if '=' in expression:
                    parts = expression.split('=')
                    left_side = parts[0].strip()
                    # Usar el lado izquierdo (que tiene la x)
                    expr_str = left_side
                else:
                    expr_str = expression
            
            print(f"🔍 Expresión a graficar: {expr_str}")  # ✅ DEBUG
            
            # Normalizar expresión
            expr_str = MathSolver.normalize_expression(expr_str)
            
            # Crear función evaluable
            transformations = (standard_transformations + (implicit_multiplication_application,))
            expr = parse_expr(expr_str, transformations=transformations)
            print(f"✅ Expresión parseada: {expr}")  # ✅ DEBUG
            
            # Determinar rango de x
            if solution_x is not None:
                x_min = solution_x - 10
                x_max = solution_x + 10
            else:
                x_min = -10
                x_max = 10
            
            print(f"📐 Rango X: [{x_min}, {x_max}]")  # ✅ DEBUG
            
            # Generar puntos
            x_values = np.linspace(x_min, x_max, 100)
            y_values = []
            
            for x_val in x_values:
                try:
                    y_val = float(expr.subs(x, x_val).evalf())
                    y_values.append(y_val)
                except:
                    y_values.append(0)
            
            # Calcular punto de solución
            solution_point = None
            if solution_x is not None:
                try:
                    solution_y = float(expr.subs(x, solution_x).evalf())
                    solution_point = {"x": float(solution_x), "y": solution_y}
                    print(f"🎯 Punto solución: {solution_point}")  # ✅ DEBUG
                except:
                    pass
            
            # Filtrar valores None o infinitos
            valid_y_values = [y for y in y_values if y is not None and np.isfinite(y)]
            
            if not valid_y_values:
                print("❌ No hay valores Y válidos")  # ✅ DEBUG
                return {"can_graph": False, "error": "No se pudieron generar puntos válidos"}
            
            y_min = float(min(valid_y_values))
            y_max = float(max(valid_y_values))
            
            # Agregar margen al rango Y
            y_range = y_max - y_min
            y_min -= y_range * 0.1
            y_max += y_range * 0.1
            
            print(f"✅ Gráfico generado: {len(x_values)} puntos, Rango Y: [{y_min:.2f}, {y_max:.2f}]")  # ✅ DEBUG
            
            return {
                "can_graph": True,
                "x_values": [float(x) for x in x_values],
                "y_values": [float(y) for y in y_values],
                "solution_point": solution_point,
                "equation": expr_str,
                "x_min": float(x_min),
                "x_max": float(x_max),
                "y_min": y_min,
                "y_max": y_max,
            }
            
        except Exception as e:
            print(f"❌ Error generando gráfico: {e}")  # ✅ DEBUG
            import traceback
            traceback.print_exc()  # ✅ DEBUG: Stack trace completo
            return {
                "can_graph": False,
                "error": str(e)
            }
