# backend/fix_env.py
import os

# Contenido correcto
env_content = "DATABASE_URL=postgresql://mathtutor_user:mathtutor2026@localhost:5432/mathtutor_dev"

# 1. Eliminar .env viejo
if os.path.exists('.env'):
    os.remove('.env')
    print("🗑️ Archivo .env viejo eliminado")

# 2. Crear .env nuevo en UTF-8 puro (sin BOM)
with open('.env', 'w', encoding='utf-8') as f:
    f.write(env_content + '\n')

print("✅ Archivo .env creado correctamente en UTF-8")

# 3. Verificar
with open('.env', 'rb') as f:
    first_bytes = f.read(3)
    if first_bytes == b'\xef\xbb\xbf':
        print("⚠️ Tiene BOM UTF-8 (debería funcionar)")
    elif first_bytes[:2] == b'\xff\xfe':
        print("❌ ERROR: Todavía es UTF-16LE")
    else:
        print("✅ UTF-8 sin BOM - PERFECTO")
