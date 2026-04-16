# backend/brain_engine/config.py
import os
from pathlib import Path

# Configuración de Ollama
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434/v1")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "kiwi_kiwi/gemma-4-uncensores:e2b")

# Configuración de Memoria
PROJECT_ROOT = Path(__file__).parent.parent.parent
INDEX_FILE = PROJECT_ROOT / "backend" / "data" / "project_index.json"
CHROMA_DB_PATH = PROJECT_ROOT / "backend" / "data" / "chroma_db"

# Extensiones a indexar
INDEX_EXTENSIONS = [".py", ".dart", ".md", ".json", ".yaml", ".sql"]

# Carpetas a ignorar
IGNORE_DIRS = ["venv", ".git", "__pycache__", "build", ".dart_tool", "node_modules"]
