'use client'

import { useState } from 'react'
import styles from './MaturitySelector.module.css'

interface MaturityLevel {
    code: string
    label: string
    planCode: string
    planDesc: string
}

const MATURITY_LEVELS: MaturityLevel[] = [
    { code: 'L1', label: 'No identificada', planCode: '01', planDesc: 'Documentar e Implementar' },
    { code: 'L2', label: 'Identificada pero no documentada', planCode: '01', planDesc: 'Documentar e Implementar' },
    { code: 'L3', label: 'Documentada pero no implementada', planCode: '02', planDesc: 'Implementar' },
    { code: 'L4', label: 'Parcialmente implementada', planCode: '02', planDesc: 'Implementar' },
    { code: 'L5', label: 'Implementada sin evidencia', planCode: '03', planDesc: 'Adaptación Completa' },
    { code: 'L6', label: 'Implementada, evidencia parcial', planCode: '04', planDesc: 'Documentar' },
    { code: 'L7', label: 'Implementada, evidencia completa', planCode: '04', planDesc: 'Documentar' },
    { code: 'L8', label: 'Medida no necesaria', planCode: '05', planDesc: 'Ninguna acción' },
]

interface Props {
    value: string
    onChange: (level: string) => void
    measureTitle?: string
}

export function MaturitySelector({ value, onChange, measureTitle }: Props) {
    const selected = MATURITY_LEVELS.find(l => l.code === value)

    return (
        <div className={styles.container}>
            {measureTitle && <h4 className={styles.title}>{measureTitle}</h4>}

            <div className={styles.levelGrid}>
                {MATURITY_LEVELS.map(level => (
                    <button
                        key={level.code}
                        type="button"
                        className={`${styles.levelCard} ${value === level.code ? styles.selected : ''}`}
                        onClick={() => onChange(level.code)}
                    >
                        <span className={styles.code}>{level.code}</span>
                        <span className={styles.label}>{level.label}</span>
                    </button>
                ))}
            </div>

            {selected && (
                <div className={styles.feedback}>
                    <div className={styles.feedbackIcon}>📋</div>
                    <div className={styles.feedbackContent}>
                        <span className={styles.feedbackLabel}>Plan de Adaptación</span>
                        <strong className={styles.feedbackPlan}>
                            {selected.planCode}: {selected.planDesc}
                        </strong>
                    </div>
                </div>
            )}
        </div>
    )
}
