# Template Mapping: AESIA Checklists → Requirement Codes

## Mapeo de archivos a códigos de requisito

Este archivo define la correspondencia entre los nombres de los archivos Excel oficiales de AESIA y los códigos de requisito utilizados en la base de datos.

| Archivo Original | Código BD | Requisito |
|------------------|-----------|-----------|
| `Gestión de Calidad_Checklist.xlsx` | QUALITY_MGMT | Sistema de gestión de la calidad |
| `Gestión de riesgos_Checklist.xlsx` | RISK_MGMT | Sistema de gestión de riesgos |
| `Supervisión Humana_Checklist.xlsx` | HUMAN_OVERSIGHT | Supervisión humana |
| `Gobernanza del dato_Checklist.xlsx` | DATA_GOVERNANCE | Datos y gobernanza de datos |
| `Transparencia_Checklist.xlsx` | TRANSPARENCY | Transparencia |
| `Precision_Checklist.xlsx` | ACCURACY | Precisión |
| `Solidez_Checklist.xlsx` | ROBUSTNESS | Solidez (Robustez) |
| `Ciberseguridad_Checklist.xlsx` | CYBERSECURITY | Ciberseguridad |
| `Registros_Checklist.xlsx` | LOGGING | Registros |
| `Documentación tecnica_Checklist.xlsx` | TECHNICAL_DOC | Documentación técnica |
| `Vigilancia Poscomercializacion_Checklist.xlsx` | POST_MARKET | Vigilancia poscomercialización |
| `Gestión de incidentes_Checklist.xlsx` | INCIDENT_MGMT | Gestión de incidentes graves |

## Archivo adicional

| Archivo | Descripción |
|---------|-------------|
| `05.01 Ejemplo ilustrativo del desarrollo de un sistema de gestión de riesgos.xlsx` | Ejemplo de uso (no es template) |

## Uso en el código

```python
TEMPLATE_MAPPING = {
    'QUALITY_MGMT': 'Gestión de Calidad_Checklist.xlsx',
    'RISK_MGMT': 'Gestión de riesgos_Checklist.xlsx',
    'HUMAN_OVERSIGHT': 'Supervisión Humana_Checklist.xlsx',
    'DATA_GOVERNANCE': 'Gobernanza del dato_Checklist.xlsx',
    'TRANSPARENCY': 'Transparencia_Checklist.xlsx',
    'ACCURACY': 'Precision_Checklist.xlsx',
    'ROBUSTNESS': 'Solidez_Checklist.xlsx',
    'CYBERSECURITY': 'Ciberseguridad_Checklist.xlsx',
    'LOGGING': 'Registros_Checklist.xlsx',
    'TECHNICAL_DOC': 'Documentación tecnica_Checklist.xlsx',
    'POST_MARKET': 'Vigilancia Poscomercializacion_Checklist.xlsx',
    'INCIDENT_MGMT': 'Gestión de incidentes_Checklist.xlsx',
}
```
