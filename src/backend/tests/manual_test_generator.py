from excel_engine.generator import generate_excel
from openpyxl import load_workbook
from io import BytesIO

def test_generate_excel_with_custom_data():
    custom_measures = [
        {'id': 'TEST_MG_01', 'req': 'REQ_01', 'guide': 'Guía Test', 'desc': 'Descripción de prueba'}
    ]

    custom_measures_map = {
        'TEST_MG_01': [1, 1, 1, 1]
    }

    data = {
        'project_metadata': {'nombre': 'Proyecto Test'},
        'requirements': [],
        'measures': custom_measures,
        'measures_map': custom_measures_map,
        'assessments_mg': []
    }

    excel_bytes = generate_excel(data)

    # Load the excel and check content
    wb = load_workbook(BytesIO(excel_bytes))

    # Check measures sheet
    ws_mg = wb["4. Medidas Guía"]
    # Header is row 5, data starts at row 6
    assert ws_mg['A6'].value == 'TEST_MG_01'
    assert ws_mg['C6'].value == 'Guía Test'

    # Check relation sheet
    ws_rel = wb["5. Relación MG"]
    # Header is row 5, data starts at row 6
    assert ws_rel['A6'].value == 'TEST_MG_01'
    # Check checks
    assert ws_rel['B6'].value == '✓'
    assert ws_rel['C6'].value == '✓'

if __name__ == "__main__":
    try:
        test_generate_excel_with_custom_data()
        print("Test passed!")
    except Exception as e:
        print(f"Test failed: {e}")
        exit(1)
