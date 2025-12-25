"""
FastAPI Backend - IA_Sandbox
Sistema de Preevaluación Sandbox IA España
"""
from typing import Optional, List
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel

from services.conversion_logic import calculate_plan, calculate_all_assessments
from excel_engine.generator import generate_excel
from excel_engine.export_api import router as export_router

app = FastAPI(
    title="IA_Sandbox API",
    description="API para el Sistema de Preevaluación del Sandbox de IA España",
    version="0.1.0",
)

# Include export router
app.include_router(export_router)

# CORS para desarrollo
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============ Models ============

class ProjectMetadata(BaseModel):
    nombre: str
    sector: str
    trl: Optional[int] = None
    proveedor: Optional[str] = None
    descripcion: Optional[str] = None


class RiskProfile(BaseModel):
    nivel: Optional[str] = None
    justificacion: Optional[str] = None
    citas: Optional[List[str]] = None


class AssessmentInput(BaseModel):
    measure_id: str
    difficulty: Optional[str] = None
    maturity: Optional[str] = None


class ApplicationInput(BaseModel):
    project_metadata: ProjectMetadata
    risk_profile: Optional[RiskProfile] = None


class CalculatePlanRequest(BaseModel):
    maturity_level: str


class ExportRequest(BaseModel):
    project_metadata: ProjectMetadata
    assessments: List[AssessmentInput]


# ============ Endpoints ============

@app.get("/")
async def root():
    return {"message": "IA_Sandbox API", "version": "0.1.0"}


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/api/calculate-plan")
async def api_calculate_plan(request: CalculatePlanRequest):
    """
    Calcula el plan de adaptación para un nivel de madurez.
    Implementa la Regla Guía 16 AESIA.
    """
    plan = calculate_plan(request.maturity_level)
    return {
        "status": "success",
        "maturity_level": request.maturity_level,
        "adaptation_plan": plan
    }


@app.post("/api/calculate-assessments")
async def api_calculate_assessments(assessments: List[AssessmentInput]):
    """
    Calcula los planes de adaptación para múltiples evaluaciones.
    """
    assessments_dict = [a.model_dump() for a in assessments]
    results = calculate_all_assessments(assessments_dict)
    return {
        "status": "success",
        "assessments": results
    }


@app.post("/api/export-excel")
async def api_export_excel(request: ExportRequest):
    """
    Genera el archivo Excel de preevaluación (9 pestañas).
    """
    try:
        # Preparar datos
        assessments_dict = [a.model_dump() for a in request.assessments]
        calculated = calculate_all_assessments(assessments_dict)
        
        # Datos de requisitos (demo)
        requirements = [
            {"id": "REQ_01", "article_ref": "Art. 6-7", "title": "Sistema de gestión de riesgos"},
            {"id": "REQ_02", "article_ref": "Art. 10", "title": "Datos y gobernanza de datos"},
            {"id": "REQ_03", "article_ref": "Art. 11", "title": "Documentación técnica"},
            {"id": "REQ_09", "article_ref": "Art. 17", "title": "Sistema de gestión de calidad"},
        ]
        
        application_data = {
            "project_metadata": request.project_metadata.model_dump(),
            "requirements": requirements,
            "assessments_mg": calculated,
        }
        
        # Generar Excel
        excel_bytes = generate_excel(application_data)
        
        # Retornar archivo
        filename = f"preevaluacion_{request.project_metadata.nombre.replace(' ', '_')}.xlsx"
        return Response(
            content=excel_bytes,
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            headers={"Content-Disposition": f"attachment; filename={filename}"}
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============ Static Data Endpoints ============

@app.get("/api/requirements")
async def get_requirements():
    """Retorna los 12 requisitos del RIA."""
    return {
        "requirements": [
            {"id": "REQ_01", "article_ref": "Art. 6-7", "title": "Sistema de gestión de riesgos"},
            {"id": "REQ_02", "article_ref": "Art. 10", "title": "Datos y gobernanza de datos"},
            {"id": "REQ_03", "article_ref": "Art. 11", "title": "Documentación técnica"},
            {"id": "REQ_04", "article_ref": "Art. 12", "title": "Registro de operaciones"},
            {"id": "REQ_05", "article_ref": "Art. 13", "title": "Transparencia e información"},
            {"id": "REQ_06", "article_ref": "Art. 14", "title": "Supervisión humana"},
            {"id": "REQ_07", "article_ref": "Art. 15", "title": "Precisión, robustez y ciberseguridad"},
            {"id": "REQ_08", "article_ref": "Art. 16", "title": "Obligaciones del proveedor"},
            {"id": "REQ_09", "article_ref": "Art. 17", "title": "Sistema de gestión de calidad"},
            {"id": "REQ_10", "article_ref": "Art. 18-19", "title": "Conservación de documentación"},
            {"id": "REQ_11", "article_ref": "Art. 20-21", "title": "Registro y evaluación"},
            {"id": "REQ_12", "article_ref": "Art. 22-25", "title": "Monitorización post-comercialización"},
        ]
    }


@app.get("/api/maturity-levels")
async def get_maturity_levels():
    """Retorna los 8 niveles de madurez con sus planes."""
    return {
        "levels": [
            {"code": "L1", "label": "No identificada", "plan": "01", "plan_desc": "Documentar e Implementar"},
            {"code": "L2", "label": "Identificada, no documentada", "plan": "01", "plan_desc": "Documentar e Implementar"},
            {"code": "L3", "label": "Documentada, no implementada", "plan": "02", "plan_desc": "Implementar"},
            {"code": "L4", "label": "Parcialmente implementada", "plan": "02", "plan_desc": "Implementar"},
            {"code": "L5", "label": "Implementada sin evidencia", "plan": "03", "plan_desc": "Adaptación Completa"},
            {"code": "L6", "label": "Implementada, evidencia parcial", "plan": "04", "plan_desc": "Documentar"},
            {"code": "L7", "label": "Implementada, evidencia completa", "plan": "04", "plan_desc": "Documentar"},
            {"code": "L8", "label": "Medida no necesaria", "plan": "05", "plan_desc": "Ninguna acción"},
        ]
    }
