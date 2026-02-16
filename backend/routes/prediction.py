# backend/routes/prediction.py (NUEVO ARCHIVO)

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Dict, List, Optional
from datetime import datetime

from database.database import get_db
from intelligence.user_profile import UserIntelligenceProfile
from prediction.intervention_engine import InterventionEngine
from ai.personalized_tutor import PersonalizedTutorAgent

router = APIRouter(prefix="/api/predict", tags=["Prediction"])

# Instancias globales (en producción, usar dependency injection)
user_profile = UserIntelligenceProfile()
intervention_engine = InterventionEngine(user_profile)
tutor_agent = PersonalizedTutorAgent(user_profile)

class PredictRequest(BaseModel):
    user_id: str
    current_problem: Dict
    current_time_spent: float
    session_signals: List[Dict]
    user_context: Dict

@router.post("/intervention")
async def predict_intervention(request: PredictRequest):
    """
    Predice si el usuario necesita intervención
    """
    try:
        # 1. Predecir probabilidad de confusión
        struggle_prob = intervention_engine.predict_struggle_probability(
            user_id=request.user_id,
            current_problem=request.current_problem,
            current_time_spent=request.current_time_spent,
            session_signals=request.session_signals
        )
        
        # 2. Decidir intervención
        intervention = intervention_engine.decide_intervention(
            struggle_probability=struggle_prob,
            user_preferences={"user_id": request.user_id},
            current_context={"problem": request.current_problem}
        )
        
        if not intervention:
            return {
                "status": "ok",
                "struggle_probability": struggle_prob,
                "intervention": None,
                "message": "Usuario va bien, no intervenir"
            }
        
        # 3. Generar explicación personalizada si es necesario
        if intervention['type'] in ['socratic_question', 'guided_example']:
            explanation = tutor_agent.generate_explanation(
                user_id=request.user_id,
                problem=request.current_problem,
                intervention_type=intervention['type'],
                user_context=request.user_context
            )
            
            intervention['explanation'] = explanation
        
        return {
            "status": "intervene",
            "struggle_probability": round(struggle_prob, 3),
            "intervention": intervention
        }
        
    except Exception as e:
        raise HTTPException(500, f"Prediction error: {str(e)}")
