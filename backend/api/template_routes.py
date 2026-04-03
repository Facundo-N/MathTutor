from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
import random

from database.session import get_db
from database.models import UserProfile

router = APIRouter()

class TemplateSelectRequest(BaseModel):
    user_id: str
    topic_id: str

class TemplateSelectResponse(BaseModel):
    template_id: str
    equation: str

ACTIVE_TEMPLATES = [
    "beatmath",
    "academia_ninja",
    "destruir_seleccion",
    "candymath",
    "dardos"
]

TOPIC_EQUATIONS = {
    'linear': [
        '2x + 5 = 15',
        '3x - 4 = 11',
        'x + 10 = 25',
        '4x = 20',
        '5x - 2 = 13',
    ],
    'distributive': [
        '2(x + 3) = 14',
        '3(x - 2) = 12',
        '4(x + 1) = 20',
        '5(x - 4) = 5',
        '2(x + 5) = 18',
    ],
    'factorization': [
        'x^2 + 4x = 0',
        '2x^2 - 6x = 0',
        'x^2 + 5x = 0',
        '3x^2 + 9x = 0',
        'x^2 - 7x = 0',
    ],
    'quadratic': [
        'x^2 - 9 = 0',
        'x^2 - 16 = 0',
        'x^2 - 25 = 0',
        'x^2 - 36 = 0',
        'x^2 - 1 = 0',
    ],
    'cubic': [
        'x^3 = 8',
        'x^3 = 27',
        'x^3 = 64',
        'x^3 = 1',
        'x^3 = 125',
    ],
}

@router.post("/api/template/select", response_model=TemplateSelectResponse)
def select_template(data: TemplateSelectRequest, db: Session = Depends(get_db)):
    try:
        profile = db.query(UserProfile).filter(UserProfile.user_id == data.user_id).first()
        last_template = profile.last_template_used if profile else None

        # Filter out the last used template to avoid immediate repetition
        available_templates = [t for t in ACTIVE_TEMPLATES if t != last_template]
        
        # Fallback if somehow available_templates is empty (e.g. ACTIVE_TEMPLATES was reduced to 1)
        if not available_templates:
            available_templates = ACTIVE_TEMPLATES

        selected_template = random.choice(available_templates)

        if profile:
            profile.last_template_used = selected_template
            db.commit()

        # Select a random equation for the given topic
        equations = TOPIC_EQUATIONS.get(data.topic_id, ["x + 1 = 2"])
        selected_equation = random.choice(equations)

        return TemplateSelectResponse(
            template_id=selected_template,
            equation=selected_equation
        )

    except Exception as e:
        print(f"Error selecting template: {e}")
        raise HTTPException(status_code=500, detail=str(e))
