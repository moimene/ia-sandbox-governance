'use client'

import { useState } from 'react'
import Link from 'next/link'
import styles from './page.module.css'

interface FAQItem {
    question: string
    answer: string
    category: string
}

const FAQ_ITEMS: FAQItem[] = [
    // Sandbox
    {
        category: 'Sandbox',
        question: '¿Qué es el Sandbox de IA de España?',
        answer: 'Es un entorno controlado de pruebas establecido por el Real Decreto 817/2023 que permite a proveedores y responsables del despliegue de sistemas de IA de alto riesgo probar sus innovaciones bajo supervisión de AESIA, preparándose para el cumplimiento del Reglamento de IA europeo.'
    },
    {
        category: 'Sandbox',
        question: '¿Cuánto tiempo dura la participación en el Sandbox?',
        answer: 'La duración estándar es de 6 meses, ampliable hasta un máximo de 12 meses en casos justificados. El período específico se determina según la complejidad y necesidades del proyecto.'
    },
    {
        category: 'Sandbox',
        question: '¿Tiene algún coste participar en el Sandbox?',
        answer: 'No, la participación en el Sandbox es gratuita. Sin embargo, los participantes deben asumir sus propios costes de desarrollo, personal y recursos necesarios para el proyecto.'
    },
    // Elegibilidad
    {
        category: 'Elegibilidad',
        question: '¿Qué tipos de sistemas de IA pueden participar?',
        answer: 'Principalmente sistemas de IA de alto riesgo según el Anexo III del RIA: sistemas en áreas como biometría, infraestructuras críticas, educación, empleo, servicios esenciales, aplicación de la ley, gestión de migración y administración de justicia.'
    },
    {
        category: 'Elegibilidad',
        question: '¿Pueden participar empresas extranjeras?',
        answer: 'Sí, pueden participar empresas de cualquier país, siempre que el sistema de IA esté destinado a operar en el mercado español o afecte a ciudadanos españoles.'
    },
    {
        category: 'Elegibilidad',
        question: '¿Qué documentación se requiere para solicitar la admisión?',
        answer: 'Se requiere: descripción detallada del sistema, caso de uso propuesto, análisis de riesgos preliminar, plan de pruebas, equipo responsable, y compromiso de cumplimiento con las condiciones del Sandbox.'
    },
    // RIA
    {
        category: 'Reglamento IA',
        question: '¿Qué es el Reglamento de IA (RIA)?',
        answer: 'El Reglamento (UE) 2024/1689, conocido como AI Act o RIA, es la normativa europea que establece requisitos armonizados para sistemas de IA según su nivel de riesgo: prohibido, alto riesgo, riesgo limitado y riesgo mínimo.'
    },
    {
        category: 'Reglamento IA',
        question: '¿Cuáles son los 12 requisitos del RIA para sistemas de alto riesgo?',
        answer: '1) Sistema de gestión de calidad, 2) Gestión de riesgos, 3) Supervisión humana, 4) Datos y gobernanza, 5) Transparencia, 6) Precisión, 7) Robustez, 8) Ciberseguridad, 9) Registros, 10) Documentación técnica, 11) Vigilancia poscomercialización, 12) Gestión de incidentes.'
    },
    {
        category: 'Reglamento IA',
        question: '¿Cuándo entra plenamente en vigor el RIA?',
        answer: 'El RIA sigue una aplicación escalonada: las prohibiciones aplican desde febrero 2025, los requisitos para IA de alto riesgo desde agosto 2026, y la plena aplicación desde agosto 2027.'
    },
    // Herramienta
    {
        category: 'Herramienta',
        question: '¿Qué es esta herramienta de preevaluación?',
        answer: 'Es un sistema de autodiagnóstico basado en la Guía 16 de AESIA que permite evaluar el nivel de madurez de su sistema de IA frente a los 12 requisitos del RIA, generando un informe Excel compatible con AESIA.'
    },
    {
        category: 'Herramienta',
        question: '¿Qué significan los niveles de madurez L1-L8?',
        answer: 'L1-L2: No documentado ni implementado (Plan: Documentar e Implementar). L3-L4: Documentado pero no implementado (Plan: Implementar). L5: Documentado e implementado (Plan: Adaptación completa). L6-L7: Implementado pero no documentado (Plan: Documentar). L8: Medida no necesaria.'
    },
    {
        category: 'Herramienta',
        question: '¿Es obligatorio usar esta herramienta para participar en el Sandbox?',
        answer: 'No es obligatorio, pero la preevaluación facilita significativamente el proceso de solicitud y demuestra un análisis previo del cumplimiento normativo, lo cual es valorado positivamente por AESIA.'
    },
]

export default function FAQPage() {
    const [openItems, setOpenItems] = useState<Set<number>>(new Set())
    const [filterCategory, setFilterCategory] = useState<string>('all')

    const categories = ['all', ...Array.from(new Set(FAQ_ITEMS.map(item => item.category)))]

    const toggleItem = (index: number) => {
        const newOpenItems = new Set(openItems)
        if (newOpenItems.has(index)) {
            newOpenItems.delete(index)
        } else {
            newOpenItems.add(index)
        }
        setOpenItems(newOpenItems)
    }

    const filteredItems = filterCategory === 'all'
        ? FAQ_ITEMS
        : FAQ_ITEMS.filter(item => item.category === filterCategory)

    return (
        <div className="container" style={{ padding: 'var(--spacing-2xl) 0' }}>
            <div className={styles.header}>
                <h1>Preguntas Frecuentes</h1>
                <p>Encuentre respuestas a las dudas más comunes sobre el Sandbox de IA y el RIA</p>
            </div>

            {/* Category Filter */}
            <div className={styles.categoryFilter}>
                {categories.map(cat => (
                    <button
                        key={cat}
                        className={`${styles.filterBtn} ${filterCategory === cat ? styles.active : ''}`}
                        onClick={() => setFilterCategory(cat)}
                    >
                        {cat === 'all' ? 'Todas' : cat}
                    </button>
                ))}
            </div>

            {/* FAQ List */}
            <div className={styles.faqList}>
                {filteredItems.map((item, idx) => {
                    const globalIdx = FAQ_ITEMS.indexOf(item)
                    const isOpen = openItems.has(globalIdx)

                    return (
                        <div
                            key={globalIdx}
                            className={`${styles.faqItem} ${isOpen ? styles.open : ''}`}
                        >
                            <button
                                className={styles.faqQuestion}
                                onClick={() => toggleItem(globalIdx)}
                            >
                                <span className={styles.categoryTag}>{item.category}</span>
                                <span className={styles.questionText}>{item.question}</span>
                                <span className={styles.toggleIcon}>{isOpen ? '−' : '+'}</span>
                            </button>
                            {isOpen && (
                                <div className={styles.faqAnswer}>
                                    <p>{item.answer}</p>
                                </div>
                            )}
                        </div>
                    )
                })}
            </div>

            {/* Contact CTA */}
            <div className={styles.contactCta}>
                <h3>¿No encuentra lo que busca?</h3>
                <p>Contacte con nosotros para resolver cualquier duda adicional</p>
                <Link href="/solicitud" className="btn btn-primary">
                    Solicitar Información
                </Link>
            </div>
        </div>
    )
}
