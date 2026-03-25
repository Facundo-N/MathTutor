# backend/ai/problem_generator_ai.py

from openai import OpenAI
from typing import Dict, List
import json
import os
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

class AIProblemGenerator:
    """Genera problemas adaptativos con OpenAI"""
    
    def __init__(self):
        api_key = os.getenv('OPENAI_API_KEY')
        if not api_key:
            raise ValueError("⚠️ OPENAI_API_KEY no configurado en .env")
        
        self.client = OpenAI(api_key=api_key)
        print(f"✅ AIProblemGenerator inicializado con modelo: gpt-4o-mini")
    
    def generate_adaptive_problem(
        self,
        user_id: str,
        topic: str,
        difficulty: str,
        user_history: Dict
    ) -> Dict:
        """Genera problema ADAPTATIVO al usuario"""
        
        from database.session import SessionLocal
        from database.models import UserProfile
        
        # Obtener perfil de usuario para inyectar intereses
        db = SessionLocal()
        try:
            profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
            if profile:
                interests_list = profile.specific_interests or []
                interests = ", ".join(interests_list) if interests_list else "Ninguno en especifico"
                objective = profile.learning_objective or "practicar ejercicios"
            else:
                interests = "Ninguno en especifico"
                objective = "practicar ejercicios"
        finally:
            db.close()
        
        system_prompt = f"""Sos un generador de problemas matemáticos ADAPTATIVOS.

PERFIL DEL USUARIO:
- Intereses (usa estos temas para ambientar el problema si es posible): {interests}
- Objetivo de aprendizaje: {objective}

HISTORIAL DEL USUARIO:
- Problemas resueltos correctamente: {user_history.get('solved_count', 0)}
- Último error común: {user_history.get('last_error_type', 'ninguno')}
- Conceptos que domina: {user_history.get('mastered_concepts', [])}
- Conceptos que necesita practicar: {user_history.get('weak_concepts', [])}

TEMA: {topic}
DIFICULTAD BASE: {difficulty}

REGLAS:
- Si tiene muchos errores en un concepto, generar problema MÁS FÁCIL
- Si domina el concepto, aumentar complejidad
- Usar números "amigables" si está aprendiendo (2, 5, 10)
- Usar números complejos si ya domina (fracciones, decimales)
- Adapta la narrativa (hint, o el enunciado invisible) a los Intereses del usuario de forma útil.

Generá 1 problema en formato JSON VÁLIDO:
{{
  "expression": "ecuación matemática",
  "topic": "{topic}",
  "difficulty": "easy/medium/hard (ajustado al usuario)",
  "expected_time": 30,
  "hint": "pista adaptada al nivel y temática del usuario",
  "answer": "respuesta correcta"
}}

IMPORTANTE: Responde SOLO con el JSON, sin markdown ni explicaciones."""
        
        try:
            response = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"Generar problema de {topic} para usuario {user_id}"}
                ],
                temperature=0.7,
                max_tokens=200
            )
            
            content = response.choices[0].message.content.strip()
            
            # Limpiar markdown si viene envuelto
            if content.startswith("```"):
                content = content.split("```")[1].replace("json", "").strip()
            
            problem = json.loads(content)
            
            # Validar estructura
            required_keys = ["expression", "topic", "difficulty", "hint", "answer"]
            for key in required_keys:
                if key not in problem:
                    problem[key] = f"<falta {key}>"
            
            if "expected_time" not in problem:
                problem["expected_time"] = 30
            
            return problem
            
        except json.JSONDecodeError as e:
            print(f"❌ Error parsing JSON desde OpenAI: {e}")
            # Fallback: usar generator.py legacy
            from math_engine.generator import ProblemGenerator
            return ProblemGenerator.generate_by_topic(topic, difficulty, count=1)[0]
        except Exception as e:
            print(f"❌ Error OpenAI: {e}")
            # Fallback: usar generator.py legacy
            from math_engine.generator import ProblemGenerator
            return ProblemGenerator.generate_by_topic(topic, difficulty, count=1)[0]

        
        try:
            response = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"Generar problema de {topic} para usuario {user_id}"}
                ],
                temperature=0.7,
                max_tokens=200
            )
            
            problem = json.loads(response.choices[0].message.content)
            return problem
            
        except Exception as e:
            print(f"❌ Error OpenAI: {e}")
            # Fallback: usar generator.py legacy
            from math_engine.generator import ProblemGenerator
            return ProblemGenerator.generate_by_topic(topic, difficulty, count=1)[0]
