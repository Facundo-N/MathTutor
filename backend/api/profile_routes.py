from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional, Dict
from pydantic import BaseModel
from database.session import get_db
from database.models import UserProfile
import uuid

router = APIRouter()

class UserProfileSchema(BaseModel):
    user_id: str
    selected_contexts: Optional[List[str]] = []
    preferred_visual_style: Optional[str] = "balanced"
    manual_style_override: Optional[str] = None
    
    # ⭐ Deep Personalization Axes
    learning_objective: Optional[str] = "entender"
    preferred_tone: Optional[str] = "amigable"
    scaffolding_level: Optional[str] = "medio"
    specific_interests: Optional[List[str]] = []
    difficulty_level: Optional[str] = "medio"
    
    # Progress metrics
    mastery_scores: Optional[Dict[str, float]] = {}
    error_patterns: Optional[Dict[str, float]] = {}
    
    # Anti-repetition
    last_template_used: Optional[str] = None

@router.post("/api/profile")
def create_or_update_profile(data: UserProfileSchema, db: Session = Depends(get_db)):
    print(f"DEBUG: create_or_update_profile CALLED with data: {data}")
    try:
        profile = db.query(UserProfile).filter(UserProfile.user_id == data.user_id).first()
        
        if not profile:
            profile = UserProfile(
                user_id=data.user_id,
                selected_contexts=data.selected_contexts,
                preferred_visual_style=data.preferred_visual_style,
                manual_style_override=data.manual_style_override,
                learning_objective=data.learning_objective,
                preferred_tone=data.preferred_tone,
                scaffolding_level=data.scaffolding_level,
                specific_interests=data.specific_interests,
                difficulty_level=data.difficulty_level,
                mastery_scores=data.mastery_scores,
                error_patterns=data.error_patterns,
                last_template_used=data.last_template_used
            )
            db.add(profile)
        else:
            profile.selected_contexts = data.selected_contexts
            profile.preferred_visual_style = data.preferred_visual_style
            profile.manual_style_override = data.manual_style_override
            profile.learning_objective = data.learning_objective
            profile.preferred_tone = data.preferred_tone
            profile.scaffolding_level = data.scaffolding_level
            profile.specific_interests = data.specific_interests
            profile.difficulty_level = data.difficulty_level
            profile.mastery_scores = data.mastery_scores
            profile.error_patterns = data.error_patterns
            profile.last_template_used = data.last_template_used
        
        db.commit()
        db.refresh(profile)
        return profile
    except Exception as e:
        import traceback
        return {"error_type": type(e).__name__, "error_detail": str(e), "traceback": traceback.format_exc()}

@router.get("/api/profile/{user_id}")
def get_profile(user_id: str, db: Session = Depends(get_db)):
    profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile
