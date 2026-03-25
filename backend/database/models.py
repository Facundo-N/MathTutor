# backend/database/models.py (VERSIÓN COMPATIBLE CON PostgreSQL y SQLite)

from sqlalchemy import Column, Integer, String, DateTime, JSON, ForeignKey, Float
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
import uuid

Base = declarative_base()


class UserSession(Base):
    """
    Sesiones de usuario (cada vez que abre la app)
    """
    __tablename__ = "user_sessions"
    
    session_id = Column(String(36), primary_key=True)
    user_id = Column(String(50), index=True)  # ← AGREGUÉ index
    start_time = Column(DateTime, default=datetime.utcnow)


class UserSignal(Base):
    """
    Señales de comportamiento capturadas en tiempo real
    """
    __tablename__ = "user_signals"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(String(36), ForeignKey("user_sessions.session_id"), index=True)
    signal_type = Column(String(50))
    timestamp = Column(DateTime, default=datetime.utcnow)
    signal_metadata = Column(JSON)


class CognitiveMarker(Base):
    """
    Métricas cognitivas procesadas por Polars
    """
    __tablename__ = "cognitive_markers"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(50), index=True)
    session_id = Column(String(36), ForeignKey("user_sessions.session_id"), index=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    # Métricas cognitivas
    avg_time_per_problem = Column(Float)
    error_rate = Column(Float)
    voice_usage_percent = Column(Float)
    text_usage_percent = Column(Float)
    camera_usage_percent = Column(Float)
    hint_request_count = Column(Integer)
    
    # Estilo visual detectado
    detected_style = Column(String(20))  # "playful", "balanced", "minimal"
    confidence_score = Column(Float)  # 0.0-1.0
    
    # Estado emocional inferido
    frustration_level = Column(Float, default=0.0)  # 0.0-1.0
    engagement_level = Column(Float, default=0.5)   # 0.0-1.0
    confidence_level = Column(Float, default=0.5)   # 0.0-1.0


class PedagogicalMemory(Base):
    """
    ⭐ NUEVA TABLA - Memoria pedagógica: qué funcionó y qué NO
    """
    __tablename__ = "pedagogical_memory"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(50), index=True)
    problem_type = Column(String(50), index=True)  # "despejar_suma", "distributiva", etc.
    
    # ✅ Qué FUNCIONÓ
    effective_explanation_style = Column(JSON)  # {"type": "socratic", "verbosity": "medium"}
    effective_visual_type = Column(String(50))   # "pieces", "graph", "numberline"
    optimal_scaffolding_level = Column(Float)    # 0.0 (mínimo) - 1.0 (máximo)
    
    # ❌ Qué NO funcionó
    failed_approaches = Column(JSON)  # [{"type": "direct", "reason": "confused"}]
    
    # Contexto
    success_rate = Column(Float)  # 0.0-1.0
    total_attempts = Column(Integer, default=0)
    successful_attempts = Column(Integer, default=0)
    last_updated = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class UserProfile(Base):
    """
    ⭐ NUEVA TABLA - Perfil agregado del usuario
    """
    __tablename__ = "user_profiles"
    
    user_id = Column(String(50), primary_key=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Estadísticas generales
    total_sessions = Column(Integer, default=0)
    total_problems_solved = Column(Integer, default=0)
    
    # Preferencias detectadas
    preferred_visual_style = Column(String(20))  # "playful", "balanced", "minimal"
    detected_age_range = Column(String(20))      # "5-11", "12-17", "18+" (inferido, nunca mostrado)
    
    # Estrategias de aprendizaje
    learning_velocity = Column(Float, default=1.0)      # Qué tan rápido aprende
    preferred_modality = Column(String(20))             # "voice", "text", "mixed"
    frustration_threshold = Column(Float, default=0.7)  # Cuándo intervenir
    optimal_session_length = Column(Integer, default=15)  # minutos
    
    # Configuración manual
    manual_style_override = Column(String(20), nullable=True)  # Si usuario forzó un estilo
    auto_adapt_enabled = Column(Integer, default=1)  # 1=True, 0=False
    
    # Ejes adicionales
    favorite_topics = Column(JSON, default=[])
    learning_style = Column(String, default="balanced")
    difficulty_level = Column(String, default="medio")

    # EJES DE PERSONALIZACIÓN PROFUNDA
    learning_objective = Column(String, default="entender")
    preferred_tone = Column(String, default="amigable")
    scaffolding_level = Column(String, default="medio")
    selected_contexts = Column(JSON, default=[])
    specific_interests = Column(JSON, default=[])

    # MÉTRICAS DE PROGRESO Y ERRORES
    mastery_scores = Column(JSON, default={})
    error_patterns = Column(JSON, default={})


class SkillTracking(Base):
    """
    ⭐ NUEVA TABLA (Fase 3) - Seguimiento de Habilidades
    """
    __tablename__ = "skill_tracking"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(50), ForeignKey("user_profiles.user_id"), index=True)
    topic = Column(String(50), index=True)  # Ej: "Ecuaciones Lineales"
    
    mastery_score = Column(Float, default=0.0) # 0.0 - 100.0
    accuracy = Column(Float, default=0.0) # 0.0 - 1.0 (Porcentaje de aciertos)
    average_time = Column(Float, default=0.0) # Tiempo promedio de resolución en segundos
    total_attempts = Column(Integer, default=0)
    successful_attempts = Column(Integer, default=0)
    
    last_practiced = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

