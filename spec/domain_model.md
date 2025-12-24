# Modelo de Dominio - IA_Sandbox

## Entidades Principales

### 1. Requisito (Requirement)
Los 12 requisitos del Reglamento de IA (RIA) según Guía 16 AESIA.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | TEXT | Identificador único (REQ_01..REQ_12) |
| article_ref | TEXT | Referencia al artículo del RIA |
| title | TEXT | Título del requisito |
| description | TEXT | Descripción completa |

### 2. Medida Guía (MG)
Medidas definidas por AESIA para cumplir cada requisito.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | TEXT | Identificador único (MG_XX_YY) |
| requirement_id | TEXT | Requisito asociado |
| guide_ref | TEXT | Referencia a la guía AESIA |
| description | TEXT | Descripción de la medida |

### 3. Aplicación (Application)
Cabecera de cada solicitud de preevaluación.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | Identificador único |
| user_id | UUID | Usuario propietario |
| project_metadata | JSONB | {nombre, trl, sector, proveedor} |
| risk_profile | JSONB | {nivel, justificacion, citas} |
| status | TEXT | DRAFT, IN_PROGRESS, COMPLETED, EXPORTED |

### 4. Evaluación MG (Assessment MG)
Evaluación de cada medida guía por aplicación.

| Campo | Tipo | Valores |
|-------|------|---------|
| difficulty | TEXT | 00, 01, 02 |
| maturity | TEXT | L1..L8 |
| diagnosis_status | TEXT | 00 (Pendiente), 01 (Diagnosticada) |
| adaptation_plan | TEXT | 01..05 (calculado automáticamente) |

### 5. Medida Adicional (MA)
Medidas propuestas por el usuario fuera del catálogo AESIA.

### 6. Relación MA-Requisito
Vínculo N:M entre medidas adicionales y requisitos.

---

## Niveles de Madurez (L1-L8)

| Nivel | Descripción | Plan |
|-------|-------------|------|
| L1 | No identificada | 01 - Documentar e Implementar |
| L2 | Identificada, no documentada | 01 - Documentar e Implementar |
| L3 | Documentada, no implementada | 02 - Implementar |
| L4 | Parcialmente implementada | 02 - Implementar |
| L5 | Implementada sin evidencia | 03 - Adaptación Completa |
| L6 | Implementada, evidencia parcial | 04 - Documentar |
| L7 | Implementada, evidencia completa | 04 - Documentar |
| L8 | Cumplimiento total verificado | 05 - Ninguna acción |
