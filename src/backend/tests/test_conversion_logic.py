import pytest
from services.conversion_logic import calculate_plan, calculate_all_assessments

def test_calculate_plan_valid_levels():
    # Test all valid levels from L1 to L8
    assert calculate_plan('L1') == {'code': '01', 'description': 'Documentar e Implementar'}
    assert calculate_plan('L2') == {'code': '01', 'description': 'Documentar e Implementar'}
    assert calculate_plan('L3') == {'code': '02', 'description': 'Implementar'}
    assert calculate_plan('L4') == {'code': '02', 'description': 'Implementar'}
    assert calculate_plan('L5') == {'code': '03', 'description': 'Adaptación Completa'}
    assert calculate_plan('L6') == {'code': '04', 'description': 'Documentar'}
    assert calculate_plan('L7') == {'code': '04', 'description': 'Documentar'}
    assert calculate_plan('L8') == {'code': '05', 'description': 'Ninguna acción'}

def test_calculate_plan_invalid_level():
    # Test invalid level
    assert calculate_plan('L99') == {'code': '00', 'description': 'Error: nivel no reconocido'}
    assert calculate_plan('') == {'code': '00', 'description': 'Error: nivel no reconocido'}

def test_calculate_all_assessments():
    assessments = [
        {'id': 1, 'maturity': 'L1'},
        {'id': 2, 'maturity': 'L3'},
        {'id': 3, 'maturity': None},
        {'id': 4}
    ]

    results = calculate_all_assessments(assessments)

    assert len(results) == 4

    # Check L1
    assert results[0]['adaptation_plan'] == '01'
    assert results[0]['diagnosis_status'] == '01'

    # Check L3
    assert results[1]['adaptation_plan'] == '02'
    assert results[1]['diagnosis_status'] == '01'

    # Check None maturity
    assert results[2]['adaptation_plan'] == '00'
    assert results[2]['diagnosis_status'] == '00'
    assert results[2]['adaptation_plan_desc'] == 'Pendiente'

    # Check missing maturity
    assert results[3]['adaptation_plan'] == '00'
    assert results[3]['diagnosis_status'] == '00'
