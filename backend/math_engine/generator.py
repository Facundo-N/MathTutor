import random
from sympy import symbols, expand, simplify, latex, Rational
from typing import List, Dict
from .topics import MathTopic, Difficulty, get_range

x, y = symbols('x y')

class ProblemGenerator:
    
    @staticmethod
    def generate_arithmetic(difficulty: str, count: int = 1) -> List[Dict]:
        """Genera problemas de aritmética básica"""
        problems = []
        min_val, max_val = get_range("arithmetic", difficulty)
        
        operations = ['+', '-', '*', '/']
        
        for i in range(count):
            num1 = random.randint(min_val, max_val)
            num2 = random.randint(min_val, max_val)
            
            # Evitar división por cero y divisiones no exactas en easy
            op = random.choice(operations)
            if op == '/' and difficulty == "easy":
                num1 = num2 * random.randint(2, 5)  # Divisiones exactas
            
            expression = f"{num1} {op} {num2}"
            answer = eval(expression)
            
            problems.append({
                "id": f"arith_{i}",
                "expression": expression,
                "topic": "arithmetic",
                "difficulty": difficulty,
                "answer": str(answer),
                "latex": f"{num1} {op} {num2}"
            })
        
        return problems
    
    @staticmethod
    def generate_linear_equations(difficulty: str, count: int = 1) -> List[Dict]:
        """Genera ecuaciones lineales: ax + b = c"""
        problems = []
        min_val, max_val = get_range("algebra", difficulty)
        
        for i in range(count):
            a = random.randint(2, max_val)
            b = random.randint(-max_val, max_val)
            x_val = random.randint(1, 10)
            c = a * x_val + b
            
            expression = f"{a}*x + {b} = {c}" if b >= 0 else f"{a}*x - {-b} = {c}"
            
            problems.append({
                "id": f"linear_{i}",
                "expression": expression,
                "topic": "linear_equations",
                "difficulty": difficulty,
                "answer": str(x_val),
                "latex": latex(f"{a}*x + {b} = {c}")
            })
        
        return problems
    
    @staticmethod
    def generate_quadratic_equations(difficulty: str, count: int = 1) -> List[Dict]:
        """Genera ecuaciones cuadráticas SIMPLES: Ax^2 + B = C (raíz entera exacta)
        
        Usa forma simple compatible con todas las plantillas de ejercicio del frontend.
        Garantiza que la solución sea un entero (raíz perfecta).
        """
        problems = []
        a_options = [1, 2, 3] if difficulty != 'hard' else [2, 3, 4]
        b_range = 8 if difficulty != 'hard' else 15
        root_range = (1, 6) if difficulty == 'easy' else (1, 8)
        
        for i in range(count):
            a = random.choice(a_options)
            root = random.randint(*root_range)        # x = ±root
            b = random.randint(-b_range, b_range)
            c = a * root**2 + b
            
            a_str = "" if a == 1 else str(a)
            b_str = f"+{b}" if b > 0 else (str(b) if b < 0 else "")
            expression = f"{a_str}x^2{b_str}={c}"
            
            problems.append({
                "id": f"quad_{i}",
                "expression": expression,
                "topic": "quadratic_equations",
                "difficulty": difficulty,
                "answer": f"x = ±{root}",
            })
        
        return problems
    
    @staticmethod
    def generate_cubic_equations(difficulty: str, count: int = 1) -> List[Dict]:
        """Genera ecuaciones cúbicas SIMPLES: Ax^3 = C (raíz entera exacta)
        
        Usa forma simple compatible con todas las plantillas de ejercicio del frontend.
        Garantiza que la solución sea un entero (raíz cúbica perfecta).
        """
        problems = []
        a_options = [1, 2] if difficulty != 'hard' else [2, 3]
        root_range = (1, 4) if difficulty == 'easy' else (1, 5)
        
        for i in range(count):
            a = random.choice(a_options)
            root = random.randint(*root_range)        # x = root
            c = a * root**3
            
            a_str = "" if a == 1 else str(a)
            expression = f"{a_str}x^3={c}"
            
            problems.append({
                "id": f"cubic_{i}",
                "expression": expression,
                "topic": "cubic_equations",
                "difficulty": difficulty,
                "answer": f"x = {root}",
            })
        
        return problems
    
    @staticmethod
    def generate_fractions(difficulty: str, count: int = 1) -> List[Dict]:
        """Genera operaciones con fracciones"""
        problems = []
        min_val, max_val = get_range("fractions", difficulty)
        
        operations = ['+', '-', '*', '/']
        
        for i in range(count):
            num1 = Rational(random.randint(1, max_val), random.randint(2, 10))
            num2 = Rational(random.randint(1, max_val), random.randint(2, 10))
            
            op = random.choice(operations)
            
            if op == '+':
                result = num1 + num2
            elif op == '-':
                result = num1 - num2
            elif op == '*':
                result = num1 * num2
            else:
                result = num1 / num2
            
            expression = f"{num1} {op} {num2}"
            
            problems.append({
                "id": f"frac_{i}",
                "expression": expression,
                "topic": "fractions",
                "difficulty": difficulty,
                "answer": str(result),
                "latex": latex(expression)
            })
        
        return problems
    
    @staticmethod
    def generate_by_topic(topic: str, difficulty: str, count: int = 1) -> List[Dict]:
        """Genera problemas según el tema"""
        generators = {
            "arithmetic": ProblemGenerator.generate_arithmetic,
            "linear_equations": ProblemGenerator.generate_linear_equations,
            "quadratic_equations": ProblemGenerator.generate_quadratic_equations,
            "cubic_equations": ProblemGenerator.generate_cubic_equations,
            "fractions": ProblemGenerator.generate_fractions,
        }
        
        generator = generators.get(topic, ProblemGenerator.generate_arithmetic)
        return generator(difficulty, count)
