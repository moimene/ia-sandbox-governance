"""
Export API Endpoints
Provides endpoints for generating and downloading AESIA Excel exports.
"""

from fastapi import APIRouter, Response, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import zipfile
from io import BytesIO
import os

from .template_filler import TemplateFiller, TEMPLATE_MAPPING, list_available_templates

router = APIRouter(prefix="/export", tags=["export"])

# Initialize template filler
TEMPLATES_DIR = os.path.join(os.path.dirname(__file__), '..', 'templates')
filler = TemplateFiller(TEMPLATES_DIR)


class AssessmentMG(BaseModel):
    mg_id: str
    subpart_id: str
    difficulty: Optional[str] = None
    maturity: Optional[str] = None


class AdditionalMeasure(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    file_name: Optional[str] = None


class AssessmentMA(BaseModel):
    ma_id: str
    subpart_id: str
    difficulty: Optional[str] = None
    maturity: Optional[str] = None


class MAToSubpart(BaseModel):
    ma_id: str
    subpart_id: str


class ExportRequest(BaseModel):
    requirement_code: str
    assessments_mg: List[AssessmentMG]
    measures_additional: Optional[List[AdditionalMeasure]] = None
    assessments_ma: Optional[List[AssessmentMA]] = None
    ma_to_subpart: Optional[List[MAToSubpart]] = None
    application_info: Optional[Dict[str, Any]] = None


class FullExportRequest(BaseModel):
    application_id: str
    requirements: List[ExportRequest]


@router.get("/templates")
async def get_available_templates():
    """List available templates and their status."""
    return {
        "available": list_available_templates(TEMPLATES_DIR),
        "total": len(TEMPLATE_MAPPING)
    }


@router.post("/single/{requirement_code}")
async def export_single_requirement(requirement_code: str, request: ExportRequest):
    """
    Export a single requirement's checklist as filled Excel file.
    
    Returns the Excel file as downloadable attachment.
    """
    if requirement_code not in TEMPLATE_MAPPING:
        raise HTTPException(status_code=404, detail=f"Unknown requirement: {requirement_code}")
    
    template_path = filler.get_template_path(requirement_code)
    if not template_path:
        raise HTTPException(status_code=404, detail=f"Template not found for: {requirement_code}")
    
    try:
        excel_bytes = filler.fill_template(
            requirement_code=requirement_code,
            assessments_mg=[a.dict() for a in request.assessments_mg],
            measures_additional=[m.dict() for m in request.measures_additional] if request.measures_additional else None,
            assessments_ma=[a.dict() for a in request.assessments_ma] if request.assessments_ma else None,
            ma_to_subpart=[r.dict() for r in request.ma_to_subpart] if request.ma_to_subpart else None,
            application_info=request.application_info
        )
        
        filename = f"{requirement_code}_Checklist_Filled.xlsx"
        
        return Response(
            content=excel_bytes,
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            headers={
                "Content-Disposition": f'attachment; filename="{filename}"'
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/full")
async def export_all_requirements(request: FullExportRequest):
    """
    Export all requirements as a ZIP file containing 12 Excel files.
    
    Returns a ZIP file as downloadable attachment.
    """
    zip_buffer = BytesIO()
    
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
        for req in request.requirements:
            if req.requirement_code not in TEMPLATE_MAPPING:
                continue
            
            try:
                excel_bytes = filler.fill_template(
                    requirement_code=req.requirement_code,
                    assessments_mg=[a.dict() for a in req.assessments_mg],
                    measures_additional=[m.dict() for m in req.measures_additional] if req.measures_additional else None,
                    assessments_ma=[a.dict() for a in req.assessments_ma] if req.assessments_ma else None,
                    ma_to_subpart=[r.dict() for r in req.ma_to_subpart] if req.ma_to_subpart else None,
                    application_info=req.application_info
                )
                
                filename = f"{req.requirement_code}_Checklist.xlsx"
                zip_file.writestr(filename, excel_bytes)
            except Exception as e:
                # Log error but continue with other files
                print(f"Error processing {req.requirement_code}: {e}")
    
    zip_buffer.seek(0)
    zip_content = zip_buffer.getvalue()
    
    return Response(
        content=zip_content,
        media_type="application/zip",
        headers={
            "Content-Disposition": f'attachment; filename="IA_Sandbox_Checklists_{request.application_id}.zip"'
        }
    )


@router.get("/download/{application_id}/{requirement_code}")
async def download_export(application_id: str, requirement_code: str):
    """
    Download a previously generated export from storage.
    
    This endpoint checks Supabase storage for existing exports.
    Falls back to generating a new one if not found.
    """
    # TODO: Implement Supabase storage lookup
    # For now, return 404
    raise HTTPException(
        status_code=404, 
        detail="Export not found. Use POST /export/single/{requirement_code} to generate."
    )
