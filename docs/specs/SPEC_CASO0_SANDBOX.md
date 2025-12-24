# BUILD SPEC: SISTEMA DE PREEVALUACIÓN SANDBOX IA (CASO 0)

**Proyecto:** Gatekeeper & Autodiagnóstico (AESIA Guía 16)  
**Marco Metodológico:** AL-SDLC v1.2  
**Versión Doc:** 1.0.0  
**Compliance:** RD 817/2023, Reglamento (UE) 2024/1689

---

## 1. Resumen de Arquitectura

El sistema evoluciona de un simple clasificador a una **herramienta de gestión de cumplimiento y autodiagnóstico**.

### Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Frontend | Next.js 14 + React 18 |
| Estilado | CSS Modules + Tokens Garrigues |
| Backend | Supabase (PostgreSQL + Auth) |
| Lógica | Python (FastAPI) |
| IA | OpenAI vía n8n |

---

## 2. Modelo de Datos

### 2.1 Tablas Maestras

```sql
-- REQUISITOS (Los 12 del RIA)
CREATE TABLE master_requirements (
    id TEXT PRIMARY KEY,
    article_ref TEXT,
    title TEXT,
    description TEXT
);

-- MEDIDAS GUÍA (MG - AESIA)
CREATE TABLE master_measures (
    id TEXT PRIMARY KEY,
    requirement_id TEXT REFERENCES master_requirements(id),
    guide_ref TEXT,
    description TEXT
);
```

### 2.2 Tablas Transaccionales

```sql
-- CABECERA DE SOLICITUD
CREATE TABLE applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    project_metadata JSONB,
    risk_profile JSONB,
    status TEXT DEFAULT 'DRAFT',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- EVALUACIÓN DE MEDIDAS GUÍA (MG)
CREATE TABLE assessments_mg (
    application_id UUID REFERENCES applications(id),
    measure_id TEXT REFERENCES master_measures(id),
    difficulty TEXT CHECK (difficulty IN ('00', '01', '02')),
    maturity TEXT CHECK (maturity IN ('L1','L2','L3','L4','L5','L6','L7','L8')),
    diagnosis_status TEXT DEFAULT '00',
    adaptation_plan TEXT,
    PRIMARY KEY (application_id, measure_id)
);

-- MEDIDAS ADICIONALES (MA)
CREATE TABLE measures_additional (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID REFERENCES applications(id),
    title TEXT NOT NULL,
    description TEXT,
    attachment_url TEXT,
    doc_provided BOOLEAN GENERATED ALWAYS AS (attachment_url IS NOT NULL) STORED,
    sedia_status TEXT DEFAULT '00',
    sedia_comments TEXT
);

-- CRUCE MA <-> REQUISITOS
CREATE TABLE rel_ma_requirements (
    measure_additional_id UUID REFERENCES measures_additional(id) ON DELETE CASCADE,
    requirement_id TEXT REFERENCES master_requirements(id),
    PRIMARY KEY (measure_additional_id, requirement_id)
);

-- EVALUACIÓN DE MA
CREATE TABLE assessments_ma (
    measure_additional_id UUID,
    requirement_id TEXT,
    difficulty TEXT,
    maturity TEXT,
    diagnosis_status TEXT,
    adaptation_plan TEXT,
    FOREIGN KEY (measure_additional_id, requirement_id) 
      REFERENCES rel_ma_requirements(measure_additional_id, requirement_id)
);
```

---

## 3. Lógica de Negocio

### 3.1 Algoritmo de Conversión (Regla Guía 16)

| Madurez | Código | Plan de Adaptación |
|---------|--------|-------------------|
| L1, L2 | 01 | Documentar e Implementar |
| L3, L4 | 02 | Implementar |
| L5 | 03 | Adaptación Completa |
| L6, L7 | 04 | Documentar |
| L8 | 05 | Ninguna acción |

### 3.2 Gatekeeper (Validación Pre-Exportación)

1. **Integridad MA:** Toda MA debe estar vinculada a ≥1 requisito
2. **Integridad Archivos:** Si `doc_provided=true`, URL debe ser válido
3. **Estado Diagnóstico:** No exportar si hay MGs con `diagnosis_status='00'`

---

## 4. Motor de Exportación (Excel 9 pestañas)

| # | Pestaña | Fuente |
|---|---------|--------|
| 1 | Portada | `applications` |
| 2 | Intro | Static |
| 3 | Artículo RIA | `master_requirements` |
| 4 | Medidas Guía | `master_measures` |
| 5 | Relación MG | Matriz precalculada |
| 6 | Autoev. MG | `assessments_mg` |
| 7 | Medidas MA | `measures_additional` |
| 8 | Relación MA | `rel_ma_requirements` |
| 9 | Autoev. MA | `assessments_ma` |

---

## 5. UX/UI (Tokens Garrigues)

### Colores
- **Primary:** PANTONE 3308 C (`#004438`)
- **Success:** Bright Green (`#009A77`)

### Componentes Críticos
- **MaturitySelector:** Radio group vertical con definición de cada nivel
- **Feedback inmediato:** Mostrar plan de adaptación al seleccionar nivel
- **MAWizard:** Modal 3 pasos (Definir → Vincular → Evaluar)
