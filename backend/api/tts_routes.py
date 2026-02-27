"""
backend/api/tts_routes.py
Endpoints REST para Text-to-Speech con Kokoro.
"""
import logging
from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel, Field
from typing import Optional

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/tts", tags=["TTS"])


# ==================== MODELOS PYDANTIC ====================

class TTSSynthesizeRequest(BaseModel):
    text: str = Field(..., description="Texto a sintetizar", max_length=500)
    voice: str = Field(default="ef_dora", description="Voz Kokoro a usar")
    speed: float = Field(default=1.0, ge=0.5, le=2.0, description="Velocidad 0.5–2.0")
    return_base64: bool = Field(
        default=True,
        description="Si True devuelve JSON con audio base64. Si False devuelve bytes WAV directo."
    )


class TTSSynthesizeResponse(BaseModel):
    audio_base64: str
    voice: str
    text_length: int


# ==================== ENDPOINTS ====================

@router.post("/synthesize")
async def synthesize_speech(request: TTSSynthesizeRequest):
    """
    Sintetiza texto a voz usando Kokoro TTS local (sin costo de API).
    
    - Devuelve audio WAV en base64 si return_base64=True (default, para Flutter)
    - Devuelve bytes WAV raw si return_base64=False (para debugging)
    """
    if not request.text.strip():
        raise HTTPException(status_code=400, detail="El texto no puede estar vacío")

    try:
        from services.kokoro_service import KokoroTTS, is_kokoro_available

        if not is_kokoro_available():
            raise HTTPException(
                status_code=503,
                detail=(
                    "Kokoro TTS no está disponible. "
                    "Ejecutar: python backend/scripts/download_kokoro_models.py "
                    "y luego: pip install kokoro-onnx soundfile"
                )
            )

        tts = KokoroTTS.get_instance()

        if request.return_base64:
            audio_b64 = tts.synthesize_to_base64(
                text=request.text,
                voice=request.voice,
                speed=request.speed,
            )
            return TTSSynthesizeResponse(
                audio_base64=audio_b64,
                voice=request.voice,
                text_length=len(request.text),
            )
        else:
            # Devolver WAV crudo (para testing desde browser / curl)
            wav_bytes = tts.synthesize(
                text=request.text,
                voice=request.voice,
                speed=request.speed,
            )
            return Response(
                content=wav_bytes,
                media_type="audio/wav",
                headers={"Content-Disposition": "inline; filename=tts_output.wav"},
            )

    except HTTPException:
        raise
    except FileNotFoundError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        logger.error("Error en TTS: %s", e, exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error en síntesis: {str(e)}")


@router.get("/status")
async def tts_status():
    """Verifica si Kokoro TTS está disponible y listo."""
    try:
        from services.kokoro_service import is_kokoro_available, KOKORO_MODEL_PATH, KOKORO_VOICES_PATH
        available = is_kokoro_available()
        return {
            "available": available,
            "voice": "ef_dora",
            "model_path": str(KOKORO_MODEL_PATH),
            "model_exists": KOKORO_MODEL_PATH.exists(),
            "voices_exists": KOKORO_VOICES_PATH.exists(),
            "instructions": (
                None if available else
                "Ejecutar: python backend/scripts/download_kokoro_models.py"
            ),
        }
    except Exception as e:
        return {"available": False, "error": str(e)}


@router.get("/voices")
async def list_voices():
    """Lista las voces disponibles en Kokoro."""
    return {
        "voices": [
            {"id": "ef_dora",  "lang": "es", "gender": "F", "description": "Natural, clara — SELECCIONADA"},
            {"id": "ef_bella", "lang": "es", "gender": "F", "description": "Energética"},
            {"id": "em_alex",  "lang": "es", "gender": "M", "description": "Masculina neutral"},
            {"id": "af_heart", "lang": "en", "gender": "F", "description": "Inglés femenino"},
        ],
        "default": "ef_dora",
    }
