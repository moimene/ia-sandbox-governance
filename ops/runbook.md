# IA_Sandbox - Runbook

## Información General

- **Sistema:** Sistema de Preevaluación Sandbox IA España
- **Stack:** Next.js + FastAPI + Supabase
- **Propietario:** Equipo de Innovación

---

## Credenciales Supabase (PRODUCTION)

> ⚠️ **IMPORTANTE**: Las credenciales reales NO deben estar en este archivo.
> Usar variables de entorno en `.env` files (ver sección Variables de Entorno).

| Campo | Ubicación |
|-------|-----------|
| **Project URL** | `SUPABASE_URL` en `.env` |
| **Publishable Key** | `NEXT_PUBLIC_SUPABASE_ANON_KEY` en `.env.local` |
| **Secret Key** | `SUPABASE_SERVICE_KEY` en `.env` (⚠️ solo backend) |
| **Dashboard** | https://supabase.com/dashboard |

### Obtención de Credenciales

1. Acceder a Supabase Dashboard → Settings → API
2. Copiar valores a los archivos `.env` correspondientes
3. **NUNCA** commitear archivos `.env` al repositorio

---

## Arranque del Sistema

### Frontend (Next.js)

```bash
cd src/frontend
npm install
npm run dev
# Accesible en http://localhost:3000
```

### Backend (FastAPI)

```bash
cd src/backend
pip install -r requirements.txt
uvicorn main:app --reload
# API en http://localhost:8000
# Docs en http://localhost:8000/docs
```

### Base de Datos (Supabase)

1. Ejecutar migraciones en orden:
   ```bash
   psql $DATABASE_URL -f src/migrations/FULL_MIGRATION.sql
   ```
2. O ejecutar individualmente desde `001` hasta `013`

### Smoke Tests (Catálogo)
```bash
psql $DATABASE_URL -f evals/smoke_tests/catalog_smoke_tests.sql
```

---

## Variables de Entorno

### Frontend (.env.local)

```env
NEXT_PUBLIC_SUPABASE_URL=https://[PROJECT_ID].supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=[PUBLISHABLE_KEY]
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### Backend (.env)

```env
SUPABASE_URL=https://[PROJECT_ID].supabase.co
SUPABASE_SERVICE_KEY=[SECRET_KEY]
OPENAI_API_KEY=sk-...
ENVIRONMENT=development
```

> ⚠️ **NUNCA** usar la SECRET_KEY en frontend. Solo la PUBLISHABLE_KEY es segura para cliente.

---

## Endpoints Críticos

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/export/single/{code}` | POST | Exporta checklist Excel por requisito |
| `/export/full` | POST | Exporta ZIP con todos los checklists |
| `/export/templates` | GET | Lista disponibilidad de templates |

---

## Troubleshooting

### Error: "Module not found"
```bash
pip install -r requirements.txt
```

### Error: CORS
Verificar que frontend esté en `allow_origins` de FastAPI.

### Error: Supabase connection
Verificar variables de entorno y que el proyecto esté activo.

### Error: preseed no inserta filas
Verificar que `master_mg_to_subpart` tenga datos para el requisito.

---

## Contacto

- **Innovación:** [equipo@firma.com]
- **Escalación:** [cto@firma.com]
