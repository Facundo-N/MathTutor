# backend/prediction/intervention_engine.py (NUEVO ARCHIVO)

from typing import Dict, Optional, List
import numpy as np
from datetime import datetime

class InterventionEngine:
    """
    Predice confusión ANTES del error y decide QUÉ hacer
    """
    
    def __init__(self, user_profile):
        self.profile = user_profile
        self.threshold_confusion = 0.65  # Ajustable por usuario
    
    def predict_struggle_probability(
        self,
        user_id: str,
        current_problem: Dict,
        current_time_spent: float,  # segundos
        session_signals: List[Dict]  # últimas 10 señales
    ) -> float:
        """
        Predice probabilidad de confusión (0-1)
        """
        # 1. Buscar problemas similares en historial
        similar_past = self.profile.retrieve_similar_successes(
            user_id, 
            current_problem,
            top_k=5
        )
        
        # 2. Calcular tiempo esperado basado en historial
        if similar_past['metadatas'] and similar_past['metadatas'][0]:
            # Extraer tiempos de problemas similares (simulado, ajustar según tu metadata)
            historical_times = [15, 20, 18]  # Placeholder: deberías guardarlo en metadata
            expected_time = np.mean(historical_times)
            time_ratio = current_time_spent / expected_time
        else:
            time_ratio = 1.0  # Sin historial, usar heursticas generales
        
        # 3. Analizar señales recientes de frustración
        frustration_signals = self._detect_frustration_signals(session_signals[-10:])
        
        # 4. Calcular probabilidad ponderada
        struggle_prob = (
            0.4 * min(time_ratio, 2.0) +  # 40% peso: tiempo vs. esperado
            0.3 * frustration_signals +    # 30% peso: señales emocionales
            0.3 * (1 - self._calc_historical_success_rate(similar_past))
        )
        
        return min(struggle_prob, 1.0)
    
    def _detect_frustration_signals(self, signals: List[Dict]) -> float:
        """
        Detecta frustración por: taps rápidos, errores repetidos, pausas largas
        """
        if not signals:
            return 0.0
        
        frustration_score = 0.0
        
        # Contar errores consecutivos
        errors = [s for s in signals if s.get('type') == 'error']
        if len(errors) >= 3:
            frustration_score += 0.5
        
        # Detectar taps rápidos (< 1s entre taps)
        # ... (implementar lógica)
        
        return min(frustration_score, 1.0)
    
    def _calc_historical_success_rate(self, similar_past: Dict) -> float:
        """
        Calcula tasa de éxito histórica en problemas similares
        """
        if not similar_past['metadatas'] or not similar_past['metadatas'][0]:
            return 0.5  # Sin historial, asumir 50%
        
        # Calcular promedio de effectiveness
        effectiveness_scores = [
            m.get('effectiveness', 0.5) 
            for m in similar_past['metadatas'][0]
        ]
        
        return np.mean(effectiveness_scores) if effectiveness_scores else 0.5
    
    def decide_intervention(
        self,
        struggle_probability: float,
        user_preferences: Dict,
        current_context: Dict
    ) -> Optional[Dict]:
        """
        Decide QUÉ hacer y CUÁNDO
        """
        if struggle_probability < 0.3:
            return None  # Usuario va bien, no intervenir
        
        elif struggle_probability < 0.6:
            # Intervención SUAVE: visual hint sin interrumpir
            return {
                "type": "subtle_visual_cue",
                "action": "highlight_relevant_part",
                "timing": "immediate",
                "intensity": 0.4,
            }
        
        elif struggle_probability < 0.8:
            # Intervención MEDIA: pregunta socrática
            similar_successes = self.profile.retrieve_similar_successes(
                user_preferences['user_id'],
                current_context['problem'],
                top_k=1
            )
            
            # Usar estrategia que funcionó antes
            if similar_successes['metadatas'] and similar_successes['metadatas'][0]:
                best_approach = similar_successes['metadatas'][0][0].get('strategy', 'generic')
                question = self._generate_socratic_question(best_approach)
            else:
                question = self._generate_generic_clarification()
            
            return {
                "type": "socratic_question",
                "action": "change_to_portrait",
                "content": question,
                "timing": "after_next_pause",
                "intensity": 0.65,
            }
        
        else:  # >= 0.8
            # Intervención FUERTE: ejemplo guiado
            return {
                "type": "guided_example",
                "action": "show_similar_solved_problem",
                "scaffolding_level": 0.9,
                "timing": "immediate",
                "intensity": 0.95,
            }
    
    def _generate_socratic_question(self, approach: str) -> str:
        """
        Genera pregunta socrática basada en estrategia exitosa previa
        """
        questions = {
            "algebraic": "¿Qué operación necesitás hacer para dejar x sola?",
            "visual": "Si movés ese número, ¿a dónde va?",
            "trial_error": "Probá con un número más simple primero, ¿qué pasa con 2?",
        }
        return questions.get(approach, "¿Qué estás tratando de hacer con ese término?")
    
    def _generate_generic_clarification(self) -> str:
        return "¿Por qué elegiste hacer eso? Explicame tu razonamiento."
