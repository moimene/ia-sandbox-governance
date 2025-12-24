# IA Sandbox (España) — Caso 0
## Sistema de Preevaluación + Portal de Soporte Normativo
**Especificación técnica (Blueprint interno) — v1.0**

**Owner:** Innovación  
**Target:** Equipo técnico (Frontend, Backend, Data, DevOps)  
**Stack propuesto:** Next.js 14 (App Router) + Supabase (Postgres/Auth/Storage) + FastAPI (servicio de cálculo/export Excel)  
**Principio rector:** *"Fidelidad a la Guía 16: el sistema debe comportarse como la herramienta de checklist y producir un Excel compatible con AESIA."*

---

## 0. Objetivo y alcance

### 0.1 Objetivo del Caso 0
Construir un sistema que permita a una entidad (empresa) o su asesor:
1) **Registrar** un caso de uso/proyecto candidato al Sandbox (ficha técnica + documentación base).  
2) **Realizar el autodiagnóstico** de cumplimiento del RIA mediante **12 checklists** (uno por requisito).  
3) **Generar el Plan de Adaptación (PDA)** de forma determinista (por fila/relación), y mostrar indicadores agregados.  
4) **Exportar** los resultados en **Excel (plantilla oficial AESIA/Guía 16)**, preservando estructura, fórmulas y formato.  
5) Proveer un **portal de soporte**: normativa, guías AESIA, proceso de participación, roles y FAQs (y opcionalmente un asistente con citación).

### 0.2 Fuera de alcance (v1.0)
- Sustituir el proceso oficial de presentación/inscripción (solo "pre-evaluación" y preparación de evidencias).
- Evaluación de conformidad completa (fase posterior); aquí solo diagnóstico + PDA.
- Automatizaciones con LLM que modifiquen contenido sin citación (si se añade IA, será con contrato de atribución).

---

## 1. Marco de referencia (producto y contexto)

### 1.1 Naturaleza de las guías
Las guías/checklists se tratarán como **material de apoyo** (no como norma), pero el sistema debe ser **fiel a su formato** y trazable.

### 1.2 Requisitos "Checklist" (12)
El sistema debe soportar las 12 áreas (una checklist por área):
1. Sistema de gestión de la calidad  
2. Sistema de gestión de riesgos  
3. Supervisión humana  
4. Datos y gobernanza de datos  
5. Transparencia  
6. Precisión  
7. Solidez (robustez)  
8. Ciberseguridad  
9. Registros  
10. Documentación técnica  
11. Vigilancia poscomercialización  
12. Gestión de incidentes graves

> Nota de implementación: cada una se exporta como **un Excel independiente** con 9 pestañas (estructura común), versionado por plantilla.

---

## 2. Roles y permisos

### 2.1 Roles
- **Empresa (ORG_MEMBER):** crea y gestiona sus propias evaluaciones y exportaciones.
- **Asesor (ADVISOR):** gestiona evaluaciones de múltiples empresas (por invitación/relación).
- **Admin/SEDIA (ADMIN_REVIEWER):** revisa y valida Medidas Adicionales (MA) y deja comentarios.

### 2.2 Permisos (alto nivel)
- Empresa/Asesor: CRUD sobre "applications" de su ámbito (multi-tenant).
- Admin: lectura global y edición restringida a campos de evaluación de MA (estado/comentarios).

---

## 3. Arquitectura de referencia

### 3.1 Diagrama (alto nivel)

```
┌─────────────────────────────────────────────────────────────┐
│                     FRONTEND (Next.js 14)                    │
│  - Landing + Solicitud de información                        │
│  - Portal de soporte (Normativa/Guías/Proceso)               │
│  - Wizard de evaluación (12 checklists)                      │
│  - Dashboard (mis casos / mis exportaciones)                 │
└──────────────────────────────┬──────────────────────────────┘
                               │ Supabase client (RLS)
┌──────────────────────────────┴──────────────────────────────┐
│                       SUPABASE (Postgres)                    │
│  - Auth + RLS + Storage                                      │
│  - Catálogos (requirements, articles, measures, mappings)    │
│  - Transaccional (applications, assessments, exports, logs)  │
└──────────────────────────────┬──────────────────────────────┘
                               │ Service role (backend)
┌──────────────────────────────┴──────────────────────────────┐
│                       BACKEND (FastAPI)                      │
│  - /api/exports/{application_id}                             │
│  - /api/checklists/{requirement_code}/export                 │
│  - Motor Excel (plantillas oficiales + openpyxl)             │
│  - Jobs/colas (opcional v1.1)                                │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Decisión clave (compatibilidad AESIA)
**No se "recrea" el Excel** desde cero: se **rellena una plantilla oficial** (por requisito y versión) para:
- preservar pestañas, fórmulas, estilos, validaciones y layout;
- minimizar divergencias con AESIA.

---

## 4. Experiencia de usuario: proceso guiado (wizard)

### 4.1 Vistas principales
1) **Landing**
   - Qué es el sandbox, para quién, qué ofrece la herramienta.
   - CTA: "Crear caso de preevaluación" / "Solicitar información".
2) **Solicitud de información (formulario)**
   - Captura: datos de contacto, entidad, sector, descripción breve, urgencia, consentimiento.
   - Salida: ticket interno + email confirmación (vía backend/n8n si aplica).
3) **Dashboard**
   - Lista de aplicaciones: estado, progreso, última exportación, responsable.
4) **Aplicación (Application)**
   - Ficha técnica del caso + accesos al wizard por requisito.
5) **Wizard por requisito (12)**
   - UI espejo de las 9 pestañas de la checklist oficial.

### 4.2 Ficha técnica (paso previo común)
Campos mínimos (v1.0):
- Identificación: nombre del sistema, versión, propietario, proveedor/responsable de despliegue.
- Contexto: sector, objetivo, usuarios destinatarios, entorno (piloto/producción).
- Clasificación: tipo de sistema (alto riesgo / otro), módulo/funcionalidad evaluada.
- Datos: tipo de datos, presencia de datos personales (sí/no), categorías especiales (sí/no).
- Evidencias: enlaces/archivos iniciales (documentación disponible).
- Contacto: persona responsable, email, rol (técnico/legal).

Validaciones:
- Campos obligatorios marcados.
- Consentimientos y política de tratamiento (si aplica).

Salida:
- "Application" en estado DRAFT → IN_PROGRESS al iniciar diagnóstico.

---

## 5. Wizard por requisito: espejo de las 9 pestañas

> Regla UX: el wizard debe forzar el avance **en el orden** de pestañas, aunque las informativas sean "solo lectura".

### 5.1 Pestañas informativas (solo lectura)
**(1) Portada (Informativa)**
- Mostrar la leyenda de confidencialidad / uso y distribución (como en plantilla).
- Acción: "Aceptar y continuar".

**(2) Intro (Informativa)**
- Resumen de cómo se usa la herramienta: qué se completa y qué se calcula.

**(3) Artículo RIA (Informativa)**
- Tabla de "apartados/subapartados" del requisito.
- Mostrar "descripción resumida" (catálogo).
- Acción: "Continuar".

**(4) Medidas Guía (MG) (Informativa)**
- Catálogo MG del requisito con:
  - ID medida (MGxx)
  - Descripción breve
  - "cuestiones orientativas" asociadas (para guiar a la entidad).
- Acción: "Continuar".

**(5) Relación MG-Apart (Informativa)**
- Matriz visual (MG ↔ apartados del artículo)
- Lectura para comprender "qué medida aplica a qué apartado".

### 5.2 Pestañas operativas (captura de datos)

**(6) Autoeval MG (Operativa) — el núcleo**
La pantalla debe estar **pre-informada** con una fila por cada relación MG↔apartado del catálogo.
Campos editables (solo 2):
- **Nivel de dificultad percibido:** {00, 01, 02}
- **Nivel de madurez:** {L1…L8}

Campos auto-calculados / derivados (no editables):
- Estado Diagnóstico: {00 pendiente, 01 diagnosticada}
- Plan de Adaptación: {01..05} según mapping determinista

Funcionalidad adicional:
- "Añadir relación extra" al final (si una entidad considera que una MG aplica a un apartado adicional):
  - Seleccionar apartado adicional (del catálogo de apartados)
  - Seleccionar medida MG
  - Completar dificultad + madurez

**(7) Medidas Adicionales (MA) (Operativa)**
La entidad puede proponer medidas no recogidas en MG.
Campos por fila MA:
- MA_ID (autogenerado)
- Descripción breve (texto)
- Archivo de detalle:
  - Nombre del archivo (texto)
  - Upload en Storage (archivo)
- "Medida adicional documentada" (derivado):
  - 00 Pendiente (si no hay archivo/nombre)
  - 01 Ya aportada (si hay archivo/nombre)

Campos Admin/SEDIA (solo role ADMIN_REVIEWER):
- Evaluación SEDIA (estado): 00 Pendiente | 01 OK | 02 NO_OK
- Comentarios SEDIA

**(8) Relación MA-Apart (Operativa)**
Matriz MA ↔ apartados del artículo:
- Columnas: MA_ID (de las MA creadas)
- Filas: apartados del artículo
- Acción: marcar con "X" (UI: checkbox, pero al export debe traducirse a "X").

Reglas:
- Debe existir al menos una relación para que haya "Autoeval MA" (si hay MA).

**(9) Autoeval MA (Operativa)**
Se genera automáticamente **una fila por cada relación MA↔apartado** marcada en la pestaña anterior.
Editable (solo 2 columnas):
- Dificultad (00/01/02)
- Madurez (L1..L8)

Derivado:
- Estado diagnóstico y Plan de Adaptación (idéntica lógica que Autoeval MG).

---

## 6. Reglas deterministas (motor de negocio)

### 6.1 Enumeraciones
**Dificultad (Difficulty)**
- 00 = Alto
- 01 = Medio
- 02 = Bajo

**Madurez (Maturity)**
- L1 = no documentada ni implementada
- L2 = documentación en curso, no implementada
- L3 = documentada, no implementada
- L4 = documentada, implementación en curso
- L5 = documentada e implementada
- L6 = no documentada e implementada
- L7 = documentación en curso e implementada
- L8 = medida no necesaria para el sistema

### 6.2 Mapeo Madurez → Plan de Adaptación (PDA)
Regla determinista:

| Madurez | Plan |
|---------|------|
| L1/L2 | 01 (Documentar e implementar) |
| L3/L4 | 02 (Implementar) |
| L5 | 03 (Adaptación completa) |
| L6/L7 | 04 (Documentar) |
| L8 | 05 (Ninguna adaptación requerida) |

### 6.3 Estado diagnóstico
- Por defecto: 00 Pendiente
- Al seleccionar madurez (cualquier L1..L8): 01 Diagnosticada

---

## 7. Modelo de datos (Supabase/Postgres)

### 7.1 Principios
- Multi-tenant por organización (empresa/cliente).
- Versionado de catálogos y plantillas (porque pueden actualizarse).
- Auditoría mínima para trazabilidad.

### 7.2 Tablas maestras (catálogos)

**master_requirements**
- requirement_code (PK) — ej: QUALITY_MGMT, RISK_MGMT, …
- name
- description
- active (bool)

**master_requirement_versions**
- requirement_code (FK)
- version (semver o fecha)
- source_reference (archivo plantilla / hash)
- active (bool)
- PRIMARY KEY (requirement_code, version)

**master_article_subparts**
- requirement_code, version (FK)
- subpart_id (PK compuesto) — ej: "13.1.a"
- title_short
- description_short
- order_index

**master_measures_mg**
- requirement_code, version (FK)
- mg_id (PK compuesto) — ej: "MG03"
- description_brief
- guidance_questions (jsonb array)
- order_index

**master_mg_to_subpart**
- requirement_code, version (FK)
- mg_id
- subpart_id
- PRIMARY KEY (requirement_code, version, mg_id, subpart_id)

**master_excel_templates**
- requirement_code, version (FK)
- storage_path
- template_hash
- active (bool)

### 7.3 Tablas transaccionales

**organizations**
- id (uuid, PK)
- name
- country
- created_at

**org_members**
- org_id (FK)
- user_id (FK auth.users)
- role (ORG_MEMBER | ADVISOR | ADMIN_REVIEWER)
- PRIMARY KEY (org_id, user_id)

**applications**
- id (uuid, PK)
- org_id (FK)
- created_by (user_id)
- title
- sector
- system_version
- status (DRAFT | IN_PROGRESS | COMPLETED | EXPORTED)
- difficulty_class (00..02)
- created_at, updated_at

**application_profile**
- application_id (FK, unique)
- fields (jsonb)

**assessments_mg**
- id (uuid, PK)
- application_id (FK)
- requirement_code
- requirement_version
- mg_id
- subpart_id
- difficulty (00..02, nullable)
- maturity (L1..L8, nullable)
- diagnostic_state (00..01, derived/cached)
- plan_code (01..05, derived/cached)
- source (PRESEED | USER_ADDED)
- created_at, updated_at

**measures_additional**
- id (uuid, PK)
- application_id (FK)
- requirement_code
- description_brief
- file_name
- file_storage_path
- documented_state (00..01, derived)
- sedia_status (00..02)
- sedia_comments
- created_at, updated_at

**rel_ma_subparts**
- id (uuid, PK)
- ma_id (FK)
- subpart_id
- UNIQUE (ma_id, subpart_id)

**assessments_ma**
- id (uuid, PK)
- ma_id (FK)
- subpart_id
- difficulty (00..02, nullable)
- maturity (L1..L8, nullable)
- diagnostic_state (00..01, derived/cached)
- plan_code (01..05, derived/cached)
- created_at, updated_at

**exports**
- id (uuid, PK)
- application_id (FK)
- export_type (PER_REQUIREMENT | FULL_ZIP)
- template_version_map (jsonb)
- storage_path
- status (QUEUED | RUNNING | DONE | FAILED)
- error_message
- created_at, completed_at

**audit_logs**
- id (uuid, PK)
- org_id
- user_id
- action
- entity_type
- entity_id
- metadata (jsonb)
- created_at

### 7.4 RLS (resumen)
- organizations/org_members: acceso solo por pertenencia.
- applications y tablas hijas: acceso por org_id + membership.
- ADMIN_REVIEWER: política especial (lectura global o por orgs asignadas).

---

## 8. Backend (FastAPI): contratos y endpoints

### 8.1 Endpoints mínimos
- `POST /api/exports/application/{application_id}/full`
- `POST /api/exports/application/{application_id}/requirement/{requirement_code}`
- `GET /api/templates`
- `GET /api/health`

### 8.2 Motor de exportación (Excel)
Principios:
- Cargar plantilla oficial desde Storage (por requirement_code + version activa).
- Rellenar únicamente celdas editables.
- Detectar la pestaña por nombre.
- Detectar columnas por encabezado.
- Mantener fórmulas intactas.

---

## 9. Portal de soporte (normativa y procesos)

### 9.1 Contenido (MVP)
- Página "Qué es el Sandbox"
- Página "Guías AESIA"
- Página "Proceso de participación"
- FAQ + glosario
- Descarga/consulta de documentos

### 9.2 Opción "Asistente de soporte" (v1.1)
- Agente Q&A con RAG y citación obligatoria.

---

## 10. Estados, métricas y progreso

### 10.1 Estados de la aplicación
- DRAFT → IN_PROGRESS → COMPLETED → EXPORTED

### 10.2 Indicadores (dashboard)
- % filas MG diagnosticadas
- Distribución por Plan (01..05)
- Nº MA propuestas y % validadas
- Última exportación

---

## 11. Seguridad y cumplimiento
- Auth obligatoria (Supabase)
- RLS activado
- Storage con rutas por org_id/application_id
- Registro de auditoría
- Configuración regional EU

---

## 12. CI/CD y calidad
- GitHub Actions: lint + tests + migrations + test de export

---

## 13. Plan de implantación (8–10 semanas)

| Sprint | Semanas | Entregable |
|--------|---------|------------|
| Sprint 0 | 1 | Infra, Supabase EU, plantillas en Storage |
| Sprint 1 | 1-2 | Catálogos maestros, CRUD Applications + ficha técnica |
| Sprint 2 | 2 | Wizard 9 pestañas para 1 requisito, export |
| Sprint 3 | 2 | 12 requisitos por configuración, dashboard progreso |
| Sprint 4 | 1-2 | MA + upload + Admin SEDIA |
| Sprint 5 | 1-2 | Export ZIP full + portal soporte + UAT |

---

## 14. Criterios de aceptación
- [ ] Crear Application y completar ficha técnica
- [ ] Completar Autoeval MG con plan derivado
- [ ] Registrar MA, relacionarlas y autoevaluarlas
- [ ] Export Excel compatible (9 pestañas)
- [ ] Export full ZIP con 12 excels
- [ ] RLS impide lectura cruzada
- [ ] Trazabilidad mínima (audit_logs)

---

## 15. Apéndice A — Clasificación de dificultad global
- 00 Alto: implementación compleja
- 01 Medio: cambios relevantes pero acotados
- 02 Bajo: cambios menores

---

## 16. Apéndice B — Referencias
- Reglamento (UE) 2024/1689 (RIA)
- Real Decreto 817/2023 (sandbox España)
- Guías AESIA 1–16
