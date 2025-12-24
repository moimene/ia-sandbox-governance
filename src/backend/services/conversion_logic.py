"""
Lógica de Conversión - Regla Guía 16 AESIA
Sistema de Preevaluación Sandbox IA España
"""
from typing import TypedDict, Literal, Optional, Dict, List


class AdaptationPlan(TypedDict):
    code: str
    description: str


# Tabla de verdad oficial AESIA (Guía 16)
MATURITY_TO_PLAN: Dict[str, AdaptationPlan] = {
    'L1': {'code': '01', 'description': 'Documentar e Implementar'},
    'L2': {'code': '01', 'description': 'Documentar e Implementar'},
    'L3': {'code': '02', 'description': 'Implementar'},
    'L4': {'code': '02', 'description': 'Implementar'},
    'L5': {'code': '03', 'description': 'Adaptación Completa'},
    'L6': {'code': '04', 'description': 'Documentar'},
    'L7': {'code': '04', 'description': 'Documentar'},
    'L8': {'code': '05', 'description': 'Ninguna acción'},
}


def calculate_plan(maturity_level: str) -> AdaptationPlan:
    """
    Calcula el Plan de Adaptación basado en el nivel de madurez.
    
    Tabla de verdad oficial AESIA:
    - L1, L2 → Plan 01: Documentar e Implementar
    - L3, L4 → Plan 02: Implementar
    - L5 → Plan 03: Adaptación Completa
    - L6, L7 → Plan 04: Documentar
    - L8 → Plan 05: Ninguna acción
    
    Args:
        maturity_level: Nivel de madurez (L1-L8)
        
    Returns:
        AdaptationPlan con código y descripción del plan
    """
    return MATURITY_TO_PLAN.get(
        maturity_level,
        {'code': '00', 'description': 'Error: nivel no reconocido'}
    )


def get_diagnosis_status(maturity_level: Optional[str]) -> str:
    """
    Determina el estado de diagnóstico basado en si hay un nivel asignado.
    
    Returns:
        '00' si pendiente, '01' si diagnosticada
    """
    return '01' if maturity_level else '00'


def calculate_all_assessments(assessments: List[dict]) -> List[dict]:
    """
    Calcula los planes de adaptación para una lista de evaluaciones.
    
    Args:
        assessments: Lista de evaluaciones con 'maturity' opcional
        
    Returns:
        Lista de evaluaciones con 'adaptation_plan' y 'diagnosis_status' calculados
    """
    results = []
    for assessment in assessments:
        maturity = assessment.get('maturity')
        plan = calculate_plan(maturity) if maturity else {'code': '00', 'description': 'Pendiente'}
        
        results.append({
            **assessment,
            'adaptation_plan': plan['code'],
            'adaptation_plan_desc': plan['description'],
            'diagnosis_status': get_diagnosis_status(maturity),
        })
    
    return results
