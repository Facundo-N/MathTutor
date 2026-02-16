# 🚀 SETUP OpenAI - MathTutor Backend

## ✅ PASO 1: Instalar Dependencias

```powershell
cd backend
pip install -r requirements.txt
```

Esto instalará:
- `fastapi>=0.100.0`
- `uvicorn[standard]>=0.23.0`
- `pydantic>=2.0.0`
- `sqlalchemy>=2.0.0`
- `python-dotenv>=1.0.0`
- `openai>=1.3.0` ⭐ NUEVO

## ✅ PASO 2: Verificar .env

El archivo `.env` ya tiene:

```env
DATABASE_URL=sqlite:///math_tutor.db
OPENAI_API_KEY=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
```

**SI QUIERES USAR OTRA API KEY:**
1. Abre `.env`
2. Reemplaza el valor de `OPENAI_API_KEY`
3. Guarda

## ✅ PASO 3: Iniciar el Backend

```powershell
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Output esperado:**

```
🚀 MATHTUTOR API v3.0 - HIPERPERSONALIZADO
==================================================
📂 Cargando .env desde: backend\.env
   OPENAI_API_KEY configurado: ✅
   DATABASE_URL configurado: ✅
==================================================
📡 MÓDULOS ACTIVOS:
   AI Problem Generator: ✅ HABILITADO ⭐ (OpenAI)
==================================================
🔹 AI PROBLEM GENERATION ⭐:
    - GET  /api/problem/generate/check      → Verificar disponibilidad de OpenAI
    - POST /api/problem/generate/adaptive   → Generar problema adaptativo (OpenAI)
    - POST /api/problem/generate/legacy     → Generar problema sin IA (random)
```

## ✅ PASO 4: Testear los Endpoints

### A. Verificar que OpenAI está disponible

```powershell
curl -X GET "http://localhost:8000/api/problem/generate/check"
```

**Response esperada:**

```json
{
  "available": true,
  "provider": "openai",
  "model": "gpt-4o-mini",
  "reason": null
}
```

### B. Generar problema CON IA (OpenAI)

```powershell
curl -X POST "http://localhost:8000/api/problem/generate/adaptive" `
  -H "Content-Type: application/json" `
  -d '{"user_id":"user123","topic":"linear_equations","difficulty":"medium"}'
```

**Response esperada:**

```json
{
  "expression": "2x + 5 = 15",
  "topic": "linear_equations",
  "difficulty": "medium",
  "expected_time": 30,
  "hint": "Resta 5 a ambos lados para aislar el término con x",
  "answer": "x = 5",
  "generated_by": "openai"
}
```

### C. Generar problema SIN IA (Fallback)

```powershell
curl -X POST "http://localhost:8000/api/problem/generate/legacy" `
  -H "Content-Type: application/json" `
  -d '{"topic":"arithmetic","difficulty":"easy"}'
```

**Response esperada:**

```json
{
  "expression": "7 + 8",
  "topic": "arithmetic",
  "difficulty": "easy",
  "expected_time": 30,
  "hint": "Aislá la variable moviendo términos",
  "answer": "15",
  "generated_by": "legacy_random"
}
```

## 📊 RESUMEN DE ENDPOINTS

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/api/problem/generate/check` | **GET** | ✅ Verificar si OpenAI está disponible |
| `/api/problem/generate/adaptive` | **POST** | ⭐ Generar problema CON IA (OpenAI) |
| `/api/problem/generate/legacy` | **POST** | 🎲 Generar problema SIN IA (random) |
| `/api/solve` | **POST** | Resolver expresión matemática |
| `/api/hints` | **POST** | Obtener pistas progresivas |
| `/api/topics` | **GET** | Listar temas disponibles |
| `/health` | **GET** | Health check con estado de componentes |

## 🔧 FLUJO EN FLUTTER

1. **Flutter** llama a `GET /api/problem/generate/check`
2. Si `available: true` → Muestra ícono ⭐ "auto_awesome" (modo IA)
3. Si `available: false` → Muestra ícono 🔀 "shuffle" (modo legacy)
4. Al generar:
   - Si OpenAI está disponible → Llama a `/api/problem/generate/adaptive`
   - Si OpenAI falla → Fallback a `/api/problem/generate/legacy`

## 🐛 TROUBLESHOOTING

### Error: "OPENAI_API_KEY not configured in .env"

- Verifica que `.env` exista en `backend/`
- Verifica que tenga `OPENAI_API_KEY=sk-proj-...`
- Reinicia el backend (Ctrl+C y vuelve a ejecutar)

### Error: "openai module not installed"

```powershell
pip install openai>=1.3.0
```

### Error: "Failed to initialize OpenAI client"

- Verifica que la API key sea válida
- Verifica que tengas créditos en tu cuenta OpenAI
- Prueba la API key en https://platform.openai.com/account/api-keys

### El endpoint `/check` retorna `available: false`

Verifica el log del backend:

```
❌ OPENAI_API_KEY no configurado
❌ openai no está instalado
❌ Error inicializando OpenAI cliente: ...
```

## 📚 Documentación Interactiva

Una vez corriendo el backend, accede a:

```
http://localhost:8000/docs
```

Aquí puedes:
- ✅ Ver todos los endpoints
- ✅ Probar endpoints directamente
- ✅ Ver esquemas de request/response

## ✨ VERIFICACIÓN FINAL

Ejecuta este script para verificar que todo funciona:

```powershell
# 1. Verificar dependencias
python -c "import fastapi, openai, dotenv; print('✅ Todas las dependencias instaladas')"

# 2. Verificar .env cargado
python -c "from dotenv import load_dotenv; import os; load_dotenv(); print(f'OPENAI_API_KEY: {'✅' if os.getenv('OPENAI_API_KEY') else '❌'}')"

# 3. Iniciar backend
python -m uvicorn main:app --reload
```

---

**¡Listo! 🎉 OpenAI debería estar detectado en Flutter ahora.**
