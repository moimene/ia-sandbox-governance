'use client'

import { useState, useEffect, useCallback } from 'react'
import {
    preseedAssessmentsMG,
    getAssessmentsMGForRequirement,
    saveAssessmentsMGBulk,
    AssessmentMGExtended,
    createAdditionalMeasureForRequirement,
    getAdditionalMeasuresForRequirement,
    deleteAdditionalMeasureById,
    getMASubpartRelations,
    toggleMASubpartRelation,
    AdditionalMeasureExtended,
    saveAssessmentMA,
    getAssessmentsMAForRequirement
} from '../lib/supabase'
import styles from './RequirementWizard.module.css'

// Tab Components
import { Tab1Portada } from './wizard-tabs/Tab1Portada'
import { Tab2Intro } from './wizard-tabs/Tab2Intro'
import { Tab3ArticuloRIA } from './wizard-tabs/Tab3ArticuloRIA'
import { Tab4MedidasGuia } from './wizard-tabs/Tab4MedidasGuia'
import { Tab5RelacionMG } from './wizard-tabs/Tab5RelacionMG'
import { Tab6AutoevalMG } from './wizard-tabs/Tab6AutoevalMG'
import { Tab7MedidasAdicionales } from './wizard-tabs/Tab7MedidasAdicionales'
import { Tab8RelacionMA } from './wizard-tabs/Tab8RelacionMA'
import { Tab9AutoevalMA } from './wizard-tabs/Tab9AutoevalMA'

export interface Requirement {
    code: string
    title: string
    article_ref: string
    version: string
}

export interface Subpart {
    id: string
    subpart_id: string
    article_number: string
    title_short: string
    description_short?: string
    order_index: number
}

export interface MeasureGuide {
    id: string
    code: string
    title: string
    description?: string
    guidance_questions?: string[]
    order_index: number
}

export interface MGToSubpart {
    mg_id: string
    subpart_id: string
    is_primary: boolean
}

export interface AssessmentMGData {
    mg_id: string
    subpart_id: string
    difficulty: string | null
    maturity: string | null
    source: 'CATALOG' | 'USER_ADDED'
}

export interface AdditionalMeasure {
    id: string
    title: string
    description?: string
    file_name?: string
    file_storage_path?: string
}

export interface MAToSubpart {
    ma_id: string
    subpart_id: string
}

export interface AssessmentMAData {
    ma_id: string
    subpart_id: string
    difficulty: string | null
    maturity: string | null
}

interface RequirementWizardProps {
    applicationId: string
    requirement: Requirement
    subparts: Subpart[]
    measures: MeasureGuide[]
    mgToSubpart: MGToSubpart[]
    onComplete: () => void
    onBack: () => void
}

const TAB_NAMES = [
    'Portada',
    'Intro',
    'Artículo RIA',
    'Medidas Guía',
    'Relación MG',
    'Autoeval MG',
    'Medidas Adicionales',
    'Relación MA',
    'Autoeval MA'
]

export function RequirementWizard({
    applicationId,
    requirement,
    subparts,
    measures,
    mgToSubpart,
    onComplete,
    onBack
}: RequirementWizardProps) {
    const [currentTab, setCurrentTab] = useState(1)
    const [portadaAccepted, setPortadaAccepted] = useState(false)

    // State for editable tabs
    const [assessmentsMG, setAssessmentsMG] = useState<AssessmentMGData[]>([])
    const [additionalMeasures, setAdditionalMeasures] = useState<AdditionalMeasure[]>([])
    const [maToSubpart, setMaToSubpart] = useState<MAToSubpart[]>([])
    const [assessmentsMA, setAssessmentsMA] = useState<AssessmentMAData[]>([])
    const [isLoading, setIsLoading] = useState(false)
    const [isSaving, setIsSaving] = useState(false)

    // Initialize assessments: preseed from catalog, then load from DB
    useEffect(() => {
        const initializeAssessments = async () => {
            setIsLoading(true)
            try {
                // 1. Call preseed RPC to create rows from master_mg_to_subpart
                await preseedAssessmentsMG(applicationId, requirement.code, requirement.version)

                // 2. Load existing assessments from database
                const dbAssessments = await getAssessmentsMGForRequirement(applicationId, requirement.code)

                if (dbAssessments.length > 0) {
                    // Map database records to frontend state
                    const assessments: AssessmentMGData[] = dbAssessments.map(a => ({
                        mg_id: a.measure_id,
                        subpart_id: a.subpart_id || '',
                        difficulty: a.difficulty,
                        maturity: a.maturity,
                        source: a.source === 'USER_ADDED' ? 'USER_ADDED' : 'CATALOG'
                    }))
                    setAssessmentsMG(assessments)
                } else {
                    // Fallback: use local mgToSubpart mapping
                    const initialAssessments: AssessmentMGData[] = mgToSubpart.map(mapping => ({
                        mg_id: mapping.mg_id,
                        subpart_id: mapping.subpart_id,
                        difficulty: null,
                        maturity: null,
                        source: 'CATALOG' as const
                    }))
                    setAssessmentsMG(initialAssessments)
                }
            } catch (error) {
                console.error('Error initializing assessments:', error)
                // Fallback to local state
                const initialAssessments: AssessmentMGData[] = mgToSubpart.map(mapping => ({
                    mg_id: mapping.mg_id,
                    subpart_id: mapping.subpart_id,
                    difficulty: null,
                    maturity: null,
                    source: 'CATALOG' as const
                }))
                setAssessmentsMG(initialAssessments)
            } finally {
                setIsLoading(false)
            }
        }

        if (applicationId && requirement.code) {
            initializeAssessments()
        }
    }, [applicationId, requirement.code, requirement.version, mgToSubpart])

    const canNavigateNext = () => {
        switch (currentTab) {
            case 1: return portadaAccepted
            case 2: return true // Intro is always passable
            case 3: return true // Article is always passable
            case 4: return true // MG catalog is always passable
            case 5: return true // Relation is always passable
            case 6: return assessmentsMG.every(a => a.maturity !== null) // All MG must be evaluated
            case 7: return true // MA creation is optional
            case 8: return true // MA relations optional (if no MA, skip)
            case 9: return assessmentsMA.every(a => a.maturity !== null) // All MA must be evaluated
            default: return true
        }
    }

    const handleNext = () => {
        if (currentTab < 9 && canNavigateNext()) {
            // Skip tabs 7-9 if there are no additional measures
            if (currentTab === 6 && additionalMeasures.length === 0) {
                onComplete()
                return
            }
            // Skip tab 9 if there are no MA-subpart relations
            if (currentTab === 8 && maToSubpart.length === 0) {
                onComplete()
                return
            }
            setCurrentTab(currentTab + 1)
        } else if (currentTab === 9) {
            onComplete()
        }
    }

    const handlePrev = () => {
        if (currentTab > 1) {
            setCurrentTab(currentTab - 1)
        } else {
            onBack()
        }
    }

    // Handler for Tab 6: Update MG assessment
    const handleMGAssessmentChange = (mg_id: string, subpart_id: string, field: 'difficulty' | 'maturity', value: string) => {
        setAssessmentsMG(prev => prev.map(a => {
            if (a.mg_id === mg_id && a.subpart_id === subpart_id) {
                return { ...a, [field]: value }
            }
            return a
        }))
    }

    // Handler for Tab 6: Add extra relation
    const handleAddMGRelation = (mg_id: string, subpart_id: string) => {
        setAssessmentsMG(prev => [...prev, {
            mg_id,
            subpart_id,
            difficulty: null,
            maturity: null,
            source: 'USER_ADDED' as const
        }])
    }

    // Auto-save assessments when they change (debounced)
    useEffect(() => {
        if (assessmentsMG.length === 0) return

        const saveTimer = setTimeout(async () => {
            setIsSaving(true)
            try {
                const toSave = assessmentsMG.map(a => ({
                    application_id: applicationId,
                    measure_id: a.mg_id,
                    subpart_id: a.subpart_id,
                    requirement_code: requirement.code,
                    requirement_version: requirement.version,
                    difficulty: a.difficulty,
                    maturity: a.maturity,
                    source: a.source
                }))
                await saveAssessmentsMGBulk(toSave)
            } catch (error) {
                console.error('Error saving assessments:', error)
            } finally {
                setIsSaving(false)
            }
        }, 1000) // 1 second debounce

        return () => clearTimeout(saveTimer)
    }, [assessmentsMG, applicationId, requirement.code, requirement.version])

    // Load existing MA data on init
    useEffect(() => {
        const loadMAData = async () => {
            if (!applicationId || !requirement.code) return

            try {
                const existingMAs = await getAdditionalMeasuresForRequirement(applicationId, requirement.code)
                if (existingMAs.length > 0) {
                    setAdditionalMeasures(existingMAs.map(ma => ({
                        id: ma.id,
                        title: ma.title,
                        description: ma.description || undefined,
                        file_name: ma.file_name || undefined,
                        file_storage_path: ma.file_storage_path || undefined
                    })))

                    const relations = await getMASubpartRelations(applicationId, requirement.code)
                    setMaToSubpart(relations.map(r => ({
                        ma_id: r.ma_id,
                        subpart_id: r.subpart_id
                    })))

                    // Load existing MA assessments
                    const existingMAAssessments = await getAssessmentsMAForRequirement(applicationId, requirement.code)
                    if (existingMAAssessments.length > 0) {
                        setAssessmentsMA(existingMAAssessments.map(a => ({
                            ma_id: a.measure_additional_id,
                            subpart_id: a.subpart_id || '',
                            difficulty: a.difficulty,
                            maturity: a.maturity
                        })))
                    }
                }
            } catch (error) {
                console.error('Error loading MA data:', error)
            }
        }

        loadMAData()
    }, [applicationId, requirement.code])

    // Debounced save for MA assessments (same pattern as MG)
    useEffect(() => {
        if (assessmentsMA.length === 0) return

        const saveTimer = setTimeout(async () => {
            setIsSaving(true)
            try {
                for (const assessment of assessmentsMA) {
                    if (assessment.difficulty || assessment.maturity) {
                        await saveAssessmentMA({
                            measure_additional_id: assessment.ma_id,
                            requirement_id: requirement.code,
                            subpart_id: assessment.subpart_id,
                            difficulty: assessment.difficulty,
                            maturity: assessment.maturity
                        })
                    }
                }
            } catch (error) {
                console.error('Error saving MA assessments:', error)
            } finally {
                setIsSaving(false)
            }
        }, 1000) // 1 second debounce

        return () => clearTimeout(saveTimer)
    }, [assessmentsMA, requirement.code])

    // Handler for Tab 7: MA CRUD (async, persists to DB)
    const handleAddMA = async (ma: AdditionalMeasure) => {
        const created = await createAdditionalMeasureForRequirement(
            applicationId,
            requirement.code,
            {
                title: ma.title,
                description: ma.description,
                file_name: ma.file_name
            }
        )
        if (created) {
            setAdditionalMeasures(prev => [...prev, {
                id: created.id,
                title: created.title,
                description: created.description || undefined,
                file_name: created.file_name || undefined,
                file_storage_path: created.file_storage_path || undefined
            }])
        }
    }

    const handleRemoveMA = async (maId: string) => {
        const success = await deleteAdditionalMeasureById(maId)
        if (success) {
            setAdditionalMeasures(prev => prev.filter(m => m.id !== maId))
            setMaToSubpart(prev => prev.filter(r => r.ma_id !== maId))
            setAssessmentsMA(prev => prev.filter(a => a.ma_id !== maId))
        }
    }

    // Handler for Tab 7: Update MA (e.g., after file upload)
    const handleUpdateMA = (maId: string, updates: Partial<AdditionalMeasure>) => {
        setAdditionalMeasures(prev => prev.map(m =>
            m.id === maId ? { ...m, ...updates } : m
        ))
    }

    // Handler for Tab 8: MA-Subpart relations (async, persists to DB)
    const handleToggleMASubpart = async (ma_id: string, subpart_id: string) => {
        const result = await toggleMASubpartRelation(ma_id, subpart_id)

        if (result.removed) {
            setMaToSubpart(prev => prev.filter(r => !(r.ma_id === ma_id && r.subpart_id === subpart_id)))
            setAssessmentsMA(prev => prev.filter(a => !(a.ma_id === ma_id && a.subpart_id === subpart_id)))
        } else if (result.added) {
            setMaToSubpart(prev => [...prev, { ma_id, subpart_id }])
            setAssessmentsMA(prev => [...prev, { ma_id, subpart_id, difficulty: null, maturity: null }])
        }
    }

    // Handler for Tab 9: Update MA assessment
    const handleMAAssessmentChange = (ma_id: string, subpart_id: string, field: 'difficulty' | 'maturity', value: string) => {
        setAssessmentsMA(prev => prev.map(a => {
            if (a.ma_id === ma_id && a.subpart_id === subpart_id) {
                return { ...a, [field]: value }
            }
            return a
        }))
    }

    // Calculate progress
    const completedMG = assessmentsMG.filter(a => a.maturity !== null).length
    const totalMG = assessmentsMG.length
    const progressMG = totalMG > 0 ? (completedMG / totalMG) * 100 : 0

    return (
        <div className={styles.wizardContainer}>
            {/* Progress Header */}
            <div className={styles.wizardHeader}>
                <div className={styles.requirementInfo}>
                    <span className={styles.requirementCode}>{requirement.code}</span>
                    <h2>{requirement.title}</h2>
                    <span className={styles.articleRef}>{requirement.article_ref}</span>
                </div>
                <div className={styles.progressInfo}>
                    <span>Pestaña {currentTab} de 9</span>
                    <span>{completedMG} / {totalMG} medidas evaluadas</span>
                    {isLoading && <span style={{ color: 'var(--garrigues-cyan)', fontSize: '0.85rem' }}>Cargando...</span>}
                    {isSaving && <span style={{ color: 'var(--garrigues-teal)', fontSize: '0.85rem' }}>Guardando...</span>}
                </div>
            </div>

            {/* Tab Navigation */}
            <div className={styles.tabNav}>
                {TAB_NAMES.map((name, idx) => (
                    <button
                        key={idx}
                        className={`${styles.tabBtn} ${currentTab === idx + 1 ? styles.active : ''} ${idx + 1 < currentTab ? styles.completed : ''}`}
                        onClick={() => idx + 1 <= currentTab && setCurrentTab(idx + 1)}
                        disabled={idx + 1 > currentTab}
                    >
                        <span className={styles.tabNumber}>{idx + 1}</span>
                        <span className={styles.tabName}>{name}</span>
                    </button>
                ))}
            </div>

            {/* Tab Content */}
            <div className={styles.tabContent}>
                {currentTab === 1 && (
                    <Tab1Portada
                        requirement={requirement}
                        accepted={portadaAccepted}
                        onAccept={() => setPortadaAccepted(true)}
                    />
                )}
                {currentTab === 2 && (
                    <Tab2Intro requirement={requirement} />
                )}
                {currentTab === 3 && (
                    <Tab3ArticuloRIA
                        requirement={requirement}
                        subparts={subparts}
                    />
                )}
                {currentTab === 4 && (
                    <Tab4MedidasGuia
                        requirement={requirement}
                        measures={measures}
                    />
                )}
                {currentTab === 5 && (
                    <Tab5RelacionMG
                        measures={measures}
                        subparts={subparts}
                        mgToSubpart={mgToSubpart}
                    />
                )}
                {currentTab === 6 && (
                    <Tab6AutoevalMG
                        measures={measures}
                        subparts={subparts}
                        assessments={assessmentsMG}
                        onAssessmentChange={handleMGAssessmentChange}
                        onAddRelation={handleAddMGRelation}
                    />
                )}
                {currentTab === 7 && (
                    <Tab7MedidasAdicionales
                        applicationId={applicationId}
                        requirementCode={requirement.code}
                        measures={additionalMeasures}
                        onAdd={handleAddMA}
                        onRemove={handleRemoveMA}
                        onUpdate={handleUpdateMA}
                    />
                )}
                {currentTab === 8 && (
                    <Tab8RelacionMA
                        additionalMeasures={additionalMeasures}
                        subparts={subparts}
                        relations={maToSubpart}
                        onToggle={handleToggleMASubpart}
                    />
                )}
                {currentTab === 9 && (
                    <Tab9AutoevalMA
                        additionalMeasures={additionalMeasures}
                        subparts={subparts}
                        assessments={assessmentsMA}
                        onAssessmentChange={handleMAAssessmentChange}
                    />
                )}
            </div>

            {/* Navigation Footer */}
            <div className={styles.wizardFooter}>
                <button
                    className="btn btn-outline"
                    onClick={handlePrev}
                >
                    ← {currentTab === 1 ? 'Volver' : 'Anterior'}
                </button>

                <div className={styles.progressBar}>
                    <div
                        className={styles.progressFill}
                        style={{ width: `${(currentTab / 9) * 100}%` }}
                    />
                </div>

                <button
                    className="btn btn-primary"
                    onClick={handleNext}
                    disabled={!canNavigateNext()}
                >
                    {currentTab === 9 ? 'Completar ✓' : 'Siguiente →'}
                </button>
            </div>
        </div>
    )
}
