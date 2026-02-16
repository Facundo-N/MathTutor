# 🚀 QUICK START: OpenAI Detection en MathTutor

## ⚡ Instalación (2 minutos)

```powershell
# 1. Entrar a directorio backend
cd "d:\flutter 2\definitiveaplicacion\demo_33_v2\backend"

# 2. Instalar dependencias (si aun no están)
python -m pip install python-dotenv openai

# 3. Verificar configuración
python test_openai_setup.py
```

## ✅ Iniciar Backend

```powershell
# 1. Desde el directorio backend/
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

# 2. Ver en consola que carga correctamente:
# - "OPENAI_API_KEY configurado: ✅"
# - "api.problem_routes importado"
```

## 🧪 Test Endpoints (Copiar y Pegar)

### Test 1: Verificar OpenAI disponible
```powershell
curl -X GET "http://127.0.0.1:8000/api/problem/generate/check"
```
**Respuesta esperada:**
```json
{"available":true,"provider":"openai","model":"gpt-4o-mini","reason":null}
```

### Test 2: Generar problema CON IA
```powershell
curl -X POST "http://127.0.0.1:8000/api/problem/generate/adaptive" `
  -H "Content-Type: application/json" `
  -d '{"user_id":"test_user","topic":"linear_equations","difficulty":"medium"}'
```
**Respuesta esperada:** Problema con `"generated_by":"openai"`

### Test 3: Generar problema SIN IA (fallback)
```powershell
curl -X POST "http://127.0.0.1:8000/api/problem/generate/legacy" `
  -H "Content-Type: application/json" `
  -d '{"topic":"arithmetic","difficulty":"easy"}'
```
**Respuesta esperada:** Problema con `"generated_by":"legacy_random"`

## 📍 URLs Útiles

- **API Base**: http://127.0.0.1:8000
- **Docs Interactivos**: http://127.0.0.1:8000/docs
- **ReDoc**: http://127.0.0.1:8000/redoc

## 📁 Archivos Modificados/Creados

✅ `backend/requirements.txt` - Agregado openai
✅ `backend/.env` - OPENAI_API_KEY configurado
✅ `backend/main.py` - Cargado load_dotenv()
✅ `backend/api/problem_routes.py` - 3 endpoints nuevos
✅ `backend/ai/problem_generator_ai.py` - Generador con OpenAI
✅ `backend/test_openai_setup.py` - Script de validación
✅ `backend/SETUP_OPENAI.md` - Guía completa
✅ `backend/IMPLEMENTACION_COMPLETADA.md` - Documentación detallada

## 🎯 Flujo en Flutter

1. Flutter llama `GET /api/problem/generate/check`
2. Backend verifica si OpenAI está disponible
3. Si `available: true` → Muestra ícono ⭐ (modo IA)
4. Si `available: false` → Muestra ícono 🔀 (modo legacy)
5. Al generar problema → Usa `/generate/adaptive` (con fallback)

## ✨ Verificación Rápida

```powershell
# En otra terminal, revisar logs:
# Deberías ver prints como:
# "Verificando disponibilidad de OpenAI..."
# "OpenAI cliente instanciado correctamente"
# "Generando problema adaptativo para user_123"
```

## ⚠️ Si no funciona

1. Verificar que `.env` está en `backend/` (no en raíz)
2. Ejecutar: `python test_openai_setup.py`
3. Revisar que imprime: "OPENAI_API_KEY configurado: True"
4. Si falta: Reiniciar la terminal/VS Code

---

**¡Listo!** 🎉 OpenAI debería estar detectado en Flutter ahora.
