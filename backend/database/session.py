# backend/database/session.py

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os

# Cargar variables de entorno
load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')

# Crear engine de SQLAlchemy
engine = create_engine(DATABASE_URL, echo=False)

# Crear SessionLocal
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    """
    Dependency para FastAPI.
    Crea una sesión de DB y la cierra después de usarla.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Crear todas las tablas en PostgreSQL"""
    from database.models import Base
    Base.metadata.create_all(bind=engine)
    print("✅ Tablas creadas exitosamente en PostgreSQL")

if __name__ == "__main__":
    # Si ejecutas este archivo directamente, crea las tablas
    init_db()
