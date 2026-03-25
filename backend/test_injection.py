"""Test the dynamic prompt injection."""
import sys
import os

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__)))

from database.session import SessionLocal, init_db
from database.models import UserProfile
import uuid

def test_prompt_injection():
    db = SessionLocal()
    try:
        # 1. Crear usuario de prueba
        test_user_id = str(uuid.uuid4())
        new_profile = UserProfile(
            user_id=test_user_id,
            learning_objective="aprobar examen de ingreso",
            preferred_tone="humor liviano",
            scaffolding_level="dame pistas rapido",
            specific_interests=["Musica", "Queen"]
        )
        db.add(new_profile)
        db.commit()
        print(f"✅ Created test profile for {test_user_id}")
        
        # 2. Simular la extracción de websocket_routes.py
        profile = db.query(UserProfile).filter(UserProfile.user_id == test_user_id).first()
        if profile:
            tone = profile.preferred_tone or "amigable"
            scaffolding = profile.scaffolding_level or "medio"
            objective = profile.learning_objective or "entender paso a paso"
            interests_list = profile.specific_interests or []
            interests = ", ".join(interests_list) if interests_list else "Ninguno"
            
            print("\n--- WEBSOCKET INJECTION ---")
            print(f"Tone: {tone}")
            print(f"Scaffolding: {scaffolding}")
            print(f"Objective: {objective}")
            print(f"Interests: {interests}")
        else:
            print("❌ Profile not found!")
            
    finally:
        # Cleanup
        db.query(UserProfile).filter(UserProfile.user_id == test_user_id).delete()
        db.commit()
        db.close()

if __name__ == "__main__":
    init_db()
    test_prompt_injection()
