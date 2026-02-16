#!/usr/bin/env python
# backend/test_openai_setup.py
"""
Script de validación para verificar que OpenAI está correctamente configurado
"""

import os
import sys
from pathlib import Path

print("=" * 60)
print("🧪 VALIDACIÓN DE SETUP OPENAI - MATHTUTOR")
print("=" * 60)

# 1. Verificar que estamos en el directorio correcto
backend_dir = Path(__file__).parent
os.chdir(backend_dir)
print(f"\n📂 Directorio de trabajo: {backend_dir}")

# 2. Verificar que .env existe
env_path = backend_dir / ".env"
if env_path.exists():
    print(f"✅ Archivo .env encontrado")
else:
    print(f"❌ Archivo .env NO encontrado en {env_path}")
    sys.exit(1)

# 3. Cargar .env
from dotenv import load_dotenv
load_dotenv(env_path)
print(f"✅ Variables de entorno cargadas desde .env")

# 4. Verificar OPENAI_API_KEY
api_key = os.getenv('OPENAI_API_KEY')
if api_key:
    masked_key = api_key[:20] + "..." + api_key[-10:]
    print(f"✅ OPENAI_API_KEY configurado: {masked_key}")
else:
    print(f"❌ OPENAI_API_KEY NO configurado en .env")
    sys.exit(1)

# 5. Verificar que openai esté instalado
try:
    from openai import OpenAI
    print(f"✅ Módulo 'openai' instalado")
except ImportError as e:
    print(f"❌ Módulo 'openai' NO instalado: {e}")
    sys.exit(1)

# 6. Intentar instanciar cliente OpenAI
try:
    client = OpenAI(api_key=api_key)
    print(f"✅ Cliente OpenAI instanciado correctamente")
except Exception as e:
    print(f"❌ Error instanciando cliente OpenAI: {e}")
    sys.exit(1)

# 7. Verificar que FastAPI esté instalado
try:
    from fastapi import FastAPI
    print(f"✅ Módulo 'fastapi' instalado")
except ImportError:
    print(f"⚠️  Módulo 'fastapi' NO instalado")

# 8. Verificar que problem_routes.py existe
problem_routes_path = backend_dir / "api" / "problem_routes.py"
if problem_routes_path.exists():
    print(f"✅ Archivo problem_routes.py encontrado")
else:
    print(f"❌ Archivo problem_routes.py NO encontrado")

# 9. Verificar que ai/problem_generator_ai.py existe
ai_generator_path = backend_dir / "ai" / "problem_generator_ai.py"
if ai_generator_path.exists():
    print(f"✅ Archivo ai/problem_generator_ai.py encontrado")
else:
    print(f"❌ Archivo ai/problem_generator_ai.py NO encontrado")

# 10. Intentar importar problem_routes
try:
    sys.path.insert(0, str(backend_dir))
    from api.problem_routes import router as problem_router
    print(f"✅ Router de problem_routes importado")
    
    # Verificar que tiene los endpoints correctos
    routes = [route.path for route in problem_router.routes]
    expected_routes = [
        "/generate/check",
        "/generate/adaptive",
        "/generate/legacy"
    ]
    
    for route in expected_routes:
        full_path = f"/api/problem{route}"
        found = any(full_path in r for r in routes)
        status = "✅" if found else "⚠️"
        print(f"  {status} Endpoint {full_path}")
    
except Exception as e:
    print(f"⚠️  Error importando problem_routes: {e}")

# 11. Intentar importar AIProblemGenerator
try:
    from ai.problem_generator_ai import AIProblemGenerator
    print(f"✅ AIProblemGenerator importado")
    
    # Intentar instanciar
    try:
        generator = AIProblemGenerator()
        print(f"✅ AIProblemGenerator instanciado")
    except Exception as e:
        print(f"⚠️  Error instanciando AIProblemGenerator: {e}")
        
except Exception as e:
    print(f"❌ Error importando AIProblemGenerator: {e}")

print("\n" + "=" * 60)
print("✨ VALIDACIÓN COMPLETADA")
print("=" * 60)
print("\n🚀 Próximo paso: Iniciar el backend con:")
print("   python -m uvicorn main:app --reload")
print("\n📍 URLs:")
print("   - API: http://localhost:8000")
print("   - Docs: http://localhost:8000/docs")
print("   - Check: http://localhost:8000/api/problem/generate/check")
print("=" * 60)
