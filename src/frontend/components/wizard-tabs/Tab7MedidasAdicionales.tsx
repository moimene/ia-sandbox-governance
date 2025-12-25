'use client'

import { useState, useRef } from 'react'
import { AdditionalMeasure } from '../RequirementWizard'
import { uploadMADocument, getMADocumentUrl, UploadProgress } from '../../lib/supabase'
import styles from './Tabs.module.css'

interface Props {
    applicationId: string
    requirementCode: string
    measures: AdditionalMeasure[]
    onAdd: (ma: AdditionalMeasure) => void
    onRemove: (id: string) => void
    onUpdate?: (id: string, updates: Partial<AdditionalMeasure>) => void
}

export function Tab7MedidasAdicionales({
    applicationId,
    requirementCode,
    measures,
    onAdd,
    onRemove,
    onUpdate
}: Props) {
    const [showForm, setShowForm] = useState(false)
    const [title, setTitle] = useState('')
    const [description, setDescription] = useState('')
    const [selectedFile, setSelectedFile] = useState<File | null>(null)
    const [uploading, setUploading] = useState<string | null>(null) // MA ID being uploaded
    const [uploadProgress, setUploadProgress] = useState(0)
    const [downloadingUrl, setDownloadingUrl] = useState<string | null>(null)
    const fileInputRef = useRef<HTMLInputElement>(null)
    const uploadInputRefs = useRef<{ [key: string]: HTMLInputElement | null }>({})

    const handleSubmit = () => {
        if (title.trim()) {
            onAdd({
                id: `MA_${Date.now()}`,
                title: title.trim(),
                description: description.trim() || undefined,
                file_name: selectedFile?.name || undefined
            })
            setTitle('')
            setDescription('')
            setSelectedFile(null)
            setShowForm(false)
            if (fileInputRef.current) {
                fileInputRef.current.value = ''
            }
        }
    }

    const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]
        if (file) {
            setSelectedFile(file)
        }
    }

    const handleUploadForMA = async (ma: AdditionalMeasure, file: File) => {
        setUploading(ma.id)
        setUploadProgress(0)

        try {
            const result = await uploadMADocument(
                applicationId,
                ma.id,
                file,
                (progress: UploadProgress) => setUploadProgress(progress.percentage)
            )

            if (result && onUpdate) {
                onUpdate(ma.id, {
                    file_name: result.fileName,
                    file_storage_path: result.path
                })
            }
        } catch (error) {
            console.error('Upload error:', error)
            alert('Error al subir el archivo. Por favor, inténtelo de nuevo.')
        } finally {
            setUploading(null)
            setUploadProgress(0)
        }
    }

    const handleExistingMAUpload = async (ma: AdditionalMeasure, e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]
        if (file) {
            await handleUploadForMA(ma, file)
        }
    }

    const handleDownload = async (ma: AdditionalMeasure) => {
        if (!ma.file_storage_path) return

        setDownloadingUrl(ma.id)
        try {
            const url = await getMADocumentUrl(ma.file_storage_path)
            if (url) {
                window.open(url, '_blank')
            } else {
                alert('Error al obtener el enlace de descarga.')
            }
        } catch (error) {
            console.error('Download error:', error)
            alert('Error al descargar el archivo.')
        } finally {
            setDownloadingUrl(null)
        }
    }

    return (
        <div className={styles.tabContainer}>
            <div className={styles.tabHeader}>
                <div>
                    <h2>Medidas Adicionales</h2>
                    <p className={styles.subtitle}>
                        Proponga medidas no recogidas en el catálogo AESIA que apliquen a su sistema
                    </p>
                </div>
                <button
                    className="btn btn-primary"
                    onClick={() => setShowForm(true)}
                >
                    + Nueva Medida
                </button>
            </div>

            {showForm && (
                <div className={styles.maForm}>
                    <h4>Nueva Medida Adicional</h4>

                    <div className="form-group">
                        <label className="form-label">Título de la medida *</label>
                        <input
                            type="text"
                            className="form-input"
                            value={title}
                            onChange={e => setTitle(e.target.value)}
                            placeholder="Ej: Auditoría externa de algoritmos"
                        />
                    </div>

                    <div className="form-group">
                        <label className="form-label">Descripción</label>
                        <textarea
                            className="form-input"
                            value={description}
                            onChange={e => setDescription(e.target.value)}
                            placeholder="Describa la medida adicional..."
                            rows={3}
                        />
                    </div>

                    <div className="form-group">
                        <label className="form-label">Documento de evidencia (opcional)</label>
                        <input
                            ref={fileInputRef}
                            type="file"
                            className="form-input"
                            onChange={handleFileSelect}
                            accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt,.zip"
                        />
                        {selectedFile && (
                            <small style={{ color: 'var(--garrigues-teal)' }}>
                                📎 {selectedFile.name} ({(selectedFile.size / 1024).toFixed(1)} KB)
                            </small>
                        )}
                        <small style={{ color: 'var(--color-gray-500)', display: 'block', marginTop: '4px' }}>
                            Formatos aceptados: PDF, Word, Excel, PowerPoint, TXT, ZIP
                        </small>
                    </div>

                    <div className={styles.formActions}>
                        <button
                            className="btn btn-primary"
                            onClick={handleSubmit}
                            disabled={!title.trim()}
                        >
                            Guardar Medida
                        </button>
                        <button
                            className="btn btn-outline"
                            onClick={() => setShowForm(false)}
                        >
                            Cancelar
                        </button>
                    </div>
                </div>
            )}

            {measures.length === 0 && !showForm ? (
                <div className={styles.emptyState}>
                    <div className={styles.emptyIcon}>📋</div>
                    <h3>No hay medidas adicionales</h3>
                    <p>
                        Las medidas adicionales son propuestas personalizadas que complementan
                        las Medidas Guía del catálogo AESIA. Son opcionales.
                    </p>
                    <button
                        className="btn btn-outline"
                        onClick={() => setShowForm(true)}
                    >
                        Crear Primera Medida
                    </button>
                </div>
            ) : (
                <div className={styles.maList}>
                    {measures.map(ma => (
                        <div key={ma.id} className={styles.maCard}>
                            <div className={styles.maHeader}>
                                <span className={styles.maId}>{ma.id}</span>
                                <button
                                    className={styles.removeBtn}
                                    onClick={() => onRemove(ma.id)}
                                    title="Eliminar"
                                >
                                    ×
                                </button>
                            </div>
                            <h4>{ma.title}</h4>
                            {ma.description && <p>{ma.description}</p>}

                            {/* File section */}
                            <div className={styles.fileSection}>
                                {ma.file_storage_path ? (
                                    // File exists - show download link
                                    <div className={styles.fileInfo}>
                                        <span>📎 {ma.file_name}</span>
                                        <button
                                            className="btn btn-outline"
                                            style={{ padding: '4px 12px', fontSize: '0.85rem' }}
                                            onClick={() => handleDownload(ma)}
                                            disabled={downloadingUrl === ma.id}
                                        >
                                            {downloadingUrl === ma.id ? '⏳' : '⬇️'} Descargar
                                        </button>
                                    </div>
                                ) : ma.file_name ? (
                                    // Pending file reference only
                                    <div className={styles.fileInfo}>
                                        📎 {ma.file_name} <small>(referencia)</small>
                                    </div>
                                ) : (
                                    // No file - show upload button
                                    <div className={styles.uploadSection}>
                                        <input
                                            type="file"
                                            ref={el => { uploadInputRefs.current[ma.id] = el }}
                                            style={{ display: 'none' }}
                                            onChange={e => handleExistingMAUpload(ma, e)}
                                            accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt,.zip"
                                        />
                                        <button
                                            className="btn btn-outline"
                                            style={{ padding: '4px 12px', fontSize: '0.85rem' }}
                                            onClick={() => uploadInputRefs.current[ma.id]?.click()}
                                            disabled={uploading === ma.id}
                                        >
                                            {uploading === ma.id ? (
                                                <span>⏳ {uploadProgress}%</span>
                                            ) : (
                                                <span>📤 Subir documento</span>
                                            )}
                                        </button>
                                    </div>
                                )}
                            </div>

                            <div className={styles.docState}>
                                {ma.file_storage_path ? (
                                    <span className={styles.docProvided}>01 - Ya aportada</span>
                                ) : ma.file_name ? (
                                    <span className={styles.docPending}>00 - Referenciada</span>
                                ) : (
                                    <span className={styles.docPending}>00 - Pendiente</span>
                                )}
                            </div>

                            {/* SEDIA Evaluation Status (ReadOnly) */}
                            {ma.sedia_evaluation_status && ma.sedia_evaluation_status !== '00' && (
                                <div className={styles.sediaStatus} style={{ marginTop: '12px', padding: '8px', background: 'var(--color-bg-subtle)', borderRadius: '4px', borderLeft: '3px solid var(--garrigues-teal)' }}>
                                    <h5 style={{ margin: '0 0 4px 0', fontSize: '0.85rem', color: 'var(--garrigues-teal)' }}>
                                        🏛️ Evaluación SEDIA
                                    </h5>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                        <span className={`badge ${ma.sedia_evaluation_status === '01' ? 'badge-success' : 'badge-error'}`}
                                            style={{
                                                padding: '2px 8px',
                                                borderRadius: '12px',
                                                fontSize: '0.75rem',
                                                background: ma.sedia_evaluation_status === '01' ? '#def7ec' : '#fde8e8',
                                                color: ma.sedia_evaluation_status === '01' ? '#03543f' : '#9b1c1c'
                                            }}>
                                            {ma.sedia_evaluation_status === '01' ? 'Aceptada (OK)' : 'Rechazada (NO_OK)'}
                                        </span>
                                        {ma.sedia_evaluator_comments && (
                                            <span style={{ fontSize: '0.8rem', color: 'var(--color-text-secondary)' }}>
                                                - {ma.sedia_evaluator_comments}
                                            </span>
                                        )}
                                    </div>
                                </div>
                            )}
                        </div>
                    ))}
                </div>
            )}

            <div className={styles.infoBox}>
                <strong>ℹ️ Nota:</strong> En la siguiente pestaña relacionará sus Medidas Adicionales
                con los apartados del artículo, y en la pestaña 9 las evaluará.
            </div>
        </div>
    )
}
