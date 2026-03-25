# backend/database/session.py

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os
from pathlib import Path

# Cargar variables de entorno
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

DATABASE_URL = os.getenv('DATABASE_URL')

# Crear engine de SQLAlchemy
engine = create_engine(DATABASE_URL, echo=False)

# Crear SessionLocal
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = None
    try:
        db = SessionLocal()
        yield db
    except Exception as e:
        import traceback
        with open("backend/db_error.log", "a") as f:
            f.write("DB CONNECTION ERROR:\n")
            traceback.print_exc(file=f)
        raise
    finally:
        if db:
            db.close()

def init_db():
    """Crear todas las tablas en PostgreSQL"""
    from database.models import Base
    Base.metadata.create_all(bind=engine)
    print("✅ Tablas creadas exitosamente en PostgreSQL")

if __name__ == "__main__":
    # Si ejecutas este archivo directamente, crea las tablas
    init_db()
