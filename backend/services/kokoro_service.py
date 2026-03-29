"""
backend/services/kokoro_service.py
Servicio de Text-to-Speech usando Kokoro ONNX (local, sin costo de API).
Voz configurada: ef_dora (español femenino, natural)
"""
import io
import os
import wave
import struct
import logging
import numpy as np
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

# Directorio de modelos (se crean en el primer arranque)
MODELS_DIR = Path(__file__).parent.parent / "models"
KOKORO_MODEL_PATH = MODELS_DIR / "kokoro-v1.0.onnx"
KOKORO_VOICES_PATH = MODELS_DIR / "voices-v1.0.bin"

# Voz seleccionada por el usuario
DEFAULT_VOICE = "af_jessica"
SAMPLE_RATE = 24000


class KokoroTTS:
    """
    Wrapper sobre kokoro-onnx para síntesis de voz local.
    Se inicializa lazy (solo cuando se necesita la primera vez).
    """

    _instance: Optional["KokoroTTS"] = None
    _kokoro = None
    _initialized = False

    @classmethod
    def get_instance(cls) -> "KokoroTTS":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance  # type: ignore[return-value]

    def _ensure_initialized(self):
        """Inicializa Kokoro lazy — solo cuando se hace la primera síntesis."""
        if self._initialized:
            return

        try:
            from kokoro_onnx import Kokoro

            # Verificar que los archivos de modelo existan
            if not KOKORO_MODEL_PATH.exists() or not KOKORO_VOICES_PATH.exists():
                logger.warning(
                    "⚠️ Modelos de Kokoro no encontrados en %s. "
                    "Ejecutar: python backend/scripts/download_kokoro_models.py",
                    MODELS_DIR,
                )
                raise FileNotFoundError(
                    f"Modelos de Kokoro no encontrados. "
                    f"Ejecutar el script de descarga primero."
                )

            self._kokoro = Kokoro(
                str(KOKORO_MODEL_PATH),
                str(KOKORO_VOICES_PATH),
            )
            self._initialized = True
            logger.info("✅ Kokoro TTS inicializado con voz '%s'", DEFAULT_VOICE)

        except ImportError:
            logger.error(
                "❌ kokoro-onnx no instalado. "
                "Ejecutar: pip install kokoro-onnx"
            )
            self._initialized = False
            raise

    def synthesize(self, text: str, voice: str = DEFAULT_VOICE, speed: float = 1.0) -> bytes:
        """
        Sintetiza texto a audio WAV.
        
        Args:
            text: Texto a sintetizar (en español)
            voice: Nombre de la voz (default: ef_dora)
            speed: Velocidad de habla (0.5 - 2.0)
            
        Returns:
            bytes: Audio en formato WAV listo para reproducir
        """
        self._ensure_initialized()

        try:
            # Generar audio con Kokoro
            samples, sample_rate = self._kokoro.create(
                text,
                voice=voice,
                speed=speed,
                lang="es",
            )

            # Convertir numpy array a bytes WAV
            wav_bytes = self._numpy_to_wav(samples, sample_rate)
            logger.info("✅ Audio sintetizado: %d caracteres → %d bytes WAV", len(text), len(wav_bytes))
            return wav_bytes

        except Exception as e:
            logger.error("❌ Error en síntesis Kokoro: %s", e)
            raise

    def synthesize_to_base64(self, text: str, voice: str = DEFAULT_VOICE, speed: float = 1.0) -> str:
        """
        Sintetiza texto y devuelve el audio como string base64.
        Útil para enviarlo directamente como JSON al cliente Flutter.
        """
        import base64
        wav_bytes = self.synthesize(text, voice=voice, speed=speed)
        return base64.b64encode(wav_bytes).decode("utf-8")

    def _numpy_to_wav(self, samples: np.ndarray, sample_rate: int) -> bytes:
        """Convierte numpy array de audio a bytes WAV en memoria."""
        buffer = io.BytesIO()

        # Normalizar a int16
        samples_int16 = (samples * 32767).astype(np.int16)

        with wave.open(buffer, "wb") as wf:
            wf.setnchannels(1)        # Mono
            wf.setsampwidth(2)        # 16-bit
            wf.setframerate(sample_rate)
            wf.writeframes(samples_int16.tobytes())

        buffer.seek(0)
        return buffer.read()


def is_kokoro_available() -> bool:
    """Verifica si Kokoro está disponible (instalado y con modelos)."""
    try:
        import kokoro_onnx
        return KOKORO_MODEL_PATH.exists() and KOKORO_VOICES_PATH.exists()
    except ImportError:
        return False
