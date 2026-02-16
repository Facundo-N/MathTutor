# backend/routes/signals.py
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, Field
import uuid

# Imports corregidos
from database.database import get_db
from database.models import UserSession, UserSignal

# ==================== PYDANTIC MODELS ====================

class UserSignalRequest(BaseModel):
    session_id: str
    user_id: str
    signal_type: str
    timestamp: str | None = None
    metadata: Dict[str, Any] = {}

class BatchSignalsRequest(BaseModel):
    signals: List[UserSignalRequest]

# 👇 NUEVO: Para Flutter SessionSignals (camelCase)
class FlutterSignalModel(BaseModel):
    type: str
    timestamp: str
    metadata: Dict[str, Any] = {}

class SessionSignalsModel(BaseModel):
    sessionId: str = Field(alias="sessionId")  # camelCase desde Flutter
    userId: str = Field(alias="userId")
    sessionStart: str = Field(alias="sessionStart")
    signals: List[FlutterSignalModel]
    
    class Config:
        populate_by_name = True  # Acepta sessionId o session_id

# SignalProcessor stub
class SignalProcessor:
    @staticmethod
    def process_user_all_sessions(user_id: str, db: Session) -> Dict[str, Any]:
        total_signals = db.query(UserSignal).filter(UserSignal.user_id == user_id).count()
        total_sessions = db.query(UserSession).filter(UserSession.user_id == user_id).count()
        return {
            "user_id": user_id,
            "total_sessions": total_sessions,
            "total_signals": total_signals,
            "avg_signals": total_signals / total_sessions if total_sessions > 0 else 0
        }
    
    @staticmethod
    def process_session_signals(session_id: str, db: Session) -> Dict[str, Any]:
        signals = db.query(UserSignal).filter(UserSignal.session_id == session_id).count()
        return {"session_id": session_id, "signals": signals, "style": "detected"}

router = APIRouter(prefix="/api/signals", tags=["Signals"])

# ==================== ENDPOINTS ====================

@router.post("/ingest")
async def ingest_session_signals(
    session: SessionSignalsModel,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """
    🎯 ENDPOINT PRINCIPAL para Flutter SignalCollector
    Recibe SessionSignals con múltiples señales en batch
    Target: <50ms
    """
    try:
        # Validar UUID
        try:
            session_uuid = uuid.UUID(session.sessionId)
        except ValueError:
            raise HTTPException(400, f"Invalid session_id UUID: {session.sessionId}")
        
        print(f"📱 Flutter batch: {len(session.signals)} signals from {session.userId}")
        
        # Crear/actualizar sesión
        db_session = db.query(UserSession).filter(
            UserSession.session_id == session.sessionId
        ).first()
        
        if not db_session:
            db_session = UserSession(
                session_id=session.sessionId,
                user_id=session.userId,
                start_time=datetime.fromisoformat(session.sessionStart.replace('Z', '+00:00'))
            )
            db.add(db_session)
            db.flush()
        
        # Guardar signals
        signals_added = 0
        for sig in session.signals:
            try:
                timestamp = datetime.fromisoformat(sig.timestamp.replace('Z', '+00:00'))
            except:
                timestamp = datetime.utcnow()
            
            db_signal = UserSignal(
                session_id=session.sessionId,
                signal_type=sig.type,
                timestamp=timestamp,
                signal_metadata=sig.metadata
            )
            db.add(db_signal)
            signals_added += 1
        
        db.commit()
        
        return {
            "status": "success",
            "signals_saved": signals_added,
            "session_id": session.sessionId,
            "message": f"✅ {signals_added} signals captured"
        }
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"❌ Error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@router.post("/ingest/single")
async def ingest_signal(
    signal: UserSignalRequest,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Captura una señal individual (alternativa). Target: <10ms"""
    try:
        session_id_uuid = uuid.UUID(signal.session_id)
        
        # Verificar/crear sesión
        session = db.query(UserSession).filter(
            UserSession.session_id == signal.session_id
        ).first()
        
        if not session:
            session = UserSession(
                session_id=signal.session_id,
                user_id=signal.user_id,
                start_time=datetime.utcnow()
            )
            db.add(session)
            db.flush()
        
        # Crear señal
        new_signal = UserSignal(
            session_id=signal.session_id,
            signal_type=signal.signal_type,
            timestamp=datetime.fromisoformat(signal.timestamp) if signal.timestamp else datetime.utcnow(),
            signal_metadata=signal.metadata
        )
        
        db.add(new_signal)
        db.commit()
        
        return {
            "status": "success",
            "signal_id": new_signal.id,
            "message": "Signal captured"
        }
    
    except (ValueError, IntegrityError) as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Invalid data: {str(e)}")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@router.post("/ingest/batch")
async def ingest_batch(
    batch: BatchSignalsRequest,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Batch de señales individuales. Target: <50ms"""
    try:
        captured = 0
        for signal in batch.signals:
            session_id_uuid = uuid.UUID(signal.session_id)
            
            session = db.query(UserSession).filter(
                UserSession.session_id == signal.session_id
            ).first()
            
            if not session:
                session = UserSession(
                    session_id=signal.session_id,
                    user_id=signal.user_id,
                    start_time=datetime.utcnow()
                )
                db.add(session)
            
            new_signal = UserSignal(
                session_id=signal.session_id,
                signal_type=signal.signal_type,
                timestamp=datetime.fromisoformat(signal.timestamp) if signal.timestamp else datetime.utcnow(),
                signal_metadata=signal.metadata
            )
            db.add(new_signal)
            captured += 1
        
        db.commit()
        return {"status": "success", "captured": captured}
    
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Batch error: {str(e)}")

@router.get("/stats/{user_id}")
async def get_user_stats(user_id: str, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Estadísticas del usuario (con conteo real de DB)"""
    result = SignalProcessor.process_user_all_sessions(user_id, db)
    return result

@router.get("/session/{session_id}/process")
async def process_session(session_id: str, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Procesa sesión con Polars"""
    result = SignalProcessor.process_session_signals(session_id, db)
    return result

@router.get("/sessions/{user_id}")
async def get_user_sessions(user_id: str, limit: int = 10, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Lista sesiones del usuario"""
    sessions = db.query(UserSession).filter(
        UserSession.user_id == user_id
    ).order_by(UserSession.start_time.desc()).limit(limit).all()
    
    result = [{
        "session_id": s.session_id,
        "start_time": s.start_time.isoformat(),
        "signal_count": db.query(UserSignal).filter(UserSignal.session_id == s.session_id).count()
    } for s in sessions]
    
    return {"user_id": user_id, "sessions": result, "count": len(result)}

@router.get("/health")
async def health_check(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Health check con stats de DB"""
    try:
        total_sessions = db.query(UserSession).count()
        total_signals = db.query(UserSignal).count()
        return {
            "status": "healthy",
            "total_sessions": total_sessions,
            "total_signals": total_signals
        }
    except Exception as e:
        raise HTTPException(500, f"DB error: {str(e)}")

@router.delete("/session/{session_id}")
async def delete_session(session_id: str, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Delete para testing"""
    signals_deleted = db.query(UserSignal).filter(UserSignal.session_id == session_id).delete()
    sessions_deleted = db.query(UserSession).filter(UserSession.session_id == session_id).delete()
    db.commit()
    return {
        "status": "success",
        "session_deleted": sessions_deleted,
        "signals_deleted": signals_deleted
    }
