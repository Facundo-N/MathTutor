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
        """Genera ecuaciones cuadráticas"""
        problems = []
        
        for i in range(count):
            # Generar con raíces enteras conocidas
            r1 = random.randint(1, 10)
            r2 = random.randint(1, 10)
            
            # (x - r1)(x - r2) = x² - (r1+r2)x + r1*r2
            a = 1
            b = -(r1 + r2)
            c = r1 * r2
            
            expression = f"x**2 + {b}*x + {c} = 0"
            
            problems.append({
                "id": f"quad_{i}",
                "expression": expression,
                "topic": "quadratic_equations",
                "difficulty": difficulty,
                "answer": f"x = {r1}, x = {r2}",
                "latex": latex(f"x**2 + {b}*x + {c}")
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
            "fractions": ProblemGenerator.generate_fractions,
        }
        
        generator = generators.get(topic, ProblemGenerator.generate_arithmetic)
        return generator(difficulty, count)
