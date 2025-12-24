'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { getUserApplications, Application } from '../../lib/supabase'
import { useAuth, useRequireAuth } from '../../lib/auth'
import styles from './page.module.css'

type ViewMode = 'empresa' | 'asesor'

interface GroupedApplications {
    [empresa: string]: Application[]
}

export default function MisEvaluacionesPage() {
    useRequireAuth()
    const router = useRouter()
    const { userOrgs, loading: authLoading } = useAuth()

    const [applications, setApplications] = useState<Application[]>([])
    const [viewMode, setViewMode] = useState<ViewMode>('empresa')
    const [loading, setLoading] = useState(true)
    const [filterStatus, setFilterStatus] = useState<string>('all')
    const [filterEmpresa, setFilterEmpresa] = useState<string>('all')

    useEffect(() => {
        // Redirect to onboarding if user has no organizations
        if (!authLoading && userOrgs.length === 0) {
            router.push('/onboarding')
            return
        }

        if (!authLoading && userOrgs.length > 0) {
            loadApplications()
        }
    }, [authLoading, userOrgs, router])

    const loadApplications = async () => {
        setLoading(true)
        const apps = await getUserApplications()
        setApplications(apps)
        setLoading(false)
    }


    // Get unique companies for filter
    const companies = Array.from(new Set(
        applications
            .map(app => app.project_metadata.proveedor || app.project_metadata.nombre)
            .filter(Boolean)
    ))

    // Group by company for advisor view
    const groupedByCompany: GroupedApplications = applications.reduce((acc, app) => {
        const empresa = app.project_metadata.proveedor || 'Sin empresa asignada'
        if (!acc[empresa]) acc[empresa] = []
        acc[empresa].push(app)
        return acc
    }, {} as GroupedApplications)

    // Filter applications
    const filteredApps = applications.filter(app => {
        if (filterStatus !== 'all' && app.status !== filterStatus) return false
        if (filterEmpresa !== 'all') {
            const empresa = app.project_metadata.proveedor || app.project_metadata.nombre
            if (empresa !== filterEmpresa) return false
        }
        return true
    })

    const getStatusBadge = (status: string) => {
        const statusConfig: Record<string, { label: string; className: string }> = {
            DRAFT: { label: 'Borrador', className: styles.statusDraft },
            IN_PROGRESS: { label: 'En Progreso', className: styles.statusProgress },
            COMPLETED: { label: 'Completada', className: styles.statusCompleted },
            EXPORTED: { label: 'Exportada', className: styles.statusExported },
        }
        const config = statusConfig[status] || { label: status, className: '' }
        return <span className={`${styles.statusBadge} ${config.className}`}>{config.label}</span>
    }

    const formatDate = (dateStr: string) => {
        return new Date(dateStr).toLocaleDateString('es-ES', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        })
    }

    if (loading) {
        return (
            <div className="container" style={{ padding: 'var(--spacing-2xl) 0' }}>
                <p>Cargando evaluaciones...</p>
            </div>
        )
    }

    return (
        <div className="container" style={{ padding: 'var(--spacing-2xl) 0' }}>
            <div className={styles.header}>
                <div>
                    <h1>Mis Evaluaciones</h1>
                    <p className={styles.subtitle}>
                        Gestiona todas tus evaluaciones de preevaluación para el Sandbox de IA
                    </p>
                </div>
                <Link href="/evaluacion" className="btn btn-primary">
                    + Nueva Evaluación
                </Link>
            </div>

            {/* View Toggle */}
            <div className={styles.viewToggle}>
                <button
                    className={`${styles.toggleBtn} ${viewMode === 'empresa' ? styles.active : ''}`}
                    onClick={() => setViewMode('empresa')}
                >
                    🏢 Vista Empresa
                </button>
                <button
                    className={`${styles.toggleBtn} ${viewMode === 'asesor' ? styles.active : ''}`}
                    onClick={() => setViewMode('asesor')}
                >
                    👔 Vista Asesor
                </button>
            </div>

            {/* Filters */}
            <div className={styles.filters}>
                <div className={styles.filterGroup}>
                    <label>Estado:</label>
                    <select
                        value={filterStatus}
                        onChange={e => setFilterStatus(e.target.value)}
                        className="form-input"
                    >
                        <option value="all">Todos</option>
                        <option value="DRAFT">Borrador</option>
                        <option value="IN_PROGRESS">En Progreso</option>
                        <option value="COMPLETED">Completada</option>
                        <option value="EXPORTED">Exportada</option>
                    </select>
                </div>

                {viewMode === 'asesor' && (
                    <div className={styles.filterGroup}>
                        <label>Empresa:</label>
                        <select
                            value={filterEmpresa}
                            onChange={e => setFilterEmpresa(e.target.value)}
                            className="form-input"
                        >
                            <option value="all">Todas</option>
                            {companies.map(company => (
                                <option key={company} value={company}>{company}</option>
                            ))}
                        </select>
                    </div>
                )}

                <div className={styles.stats}>
                    <span className={styles.statItem}>
                        📊 Total: <strong>{applications.length}</strong>
                    </span>
                    <span className={styles.statItem}>
                        ✅ Completadas: <strong>{applications.filter(a => a.status === 'COMPLETED' || a.status === 'EXPORTED').length}</strong>
                    </span>
                </div>
            </div>

            {applications.length === 0 ? (
                <div className={styles.emptyState}>
                    <div className={styles.emptyIcon}>📋</div>
                    <h3>No hay evaluaciones</h3>
                    <p>Comienza creando tu primera evaluación de preevaluación.</p>
                    <Link href="/evaluacion" className="btn btn-success">
                        Crear Primera Evaluación
                    </Link>
                </div>
            ) : viewMode === 'empresa' ? (
                /* Vista Empresa - Lista simple */
                <div className={styles.applicationsList}>
                    {filteredApps.map(app => (
                        <div key={app.id} className={styles.appCard}>
                            <div className={styles.appMain}>
                                <div className={styles.appInfo}>
                                    <h3>{app.project_metadata.nombre}</h3>
                                    <div className={styles.appMeta}>
                                        <span>📁 {app.project_metadata.sector}</span>
                                        <span>📅 {formatDate(app.created_at)}</span>
                                    </div>
                                </div>
                                {getStatusBadge(app.status)}
                            </div>

                            <div className={styles.appActions}>
                                <Link
                                    href={`/evaluacion?id=${app.id}`}
                                    className="btn btn-outline btn-sm"
                                >
                                    {app.status === 'DRAFT' || app.status === 'IN_PROGRESS' ? 'Continuar' : 'Ver'}
                                </Link>
                                <Link
                                    href={`/medidas-adicionales?app=${app.id}`}
                                    className="btn btn-outline btn-sm"
                                >
                                    MAs
                                </Link>
                            </div>
                        </div>
                    ))}
                </div>
            ) : (
                /* Vista Asesor - Agrupado por empresa */
                <div className={styles.advisorView}>
                    {Object.entries(groupedByCompany)
                        .filter(([empresa]) => filterEmpresa === 'all' || empresa === filterEmpresa)
                        .map(([empresa, apps]) => (
                            <div key={empresa} className={styles.companyGroup}>
                                <div className={styles.companyHeader}>
                                    <h3>🏢 {empresa}</h3>
                                    <span className={styles.companyCount}>{apps.length} evaluación(es)</span>
                                </div>

                                <div className={styles.companyApps}>
                                    {apps
                                        .filter(app => filterStatus === 'all' || app.status === filterStatus)
                                        .map(app => (
                                            <div key={app.id} className={styles.miniCard}>
                                                <div className={styles.miniInfo}>
                                                    <span className={styles.miniName}>{app.project_metadata.nombre}</span>
                                                    <span className={styles.miniSector}>{app.project_metadata.sector}</span>
                                                </div>
                                                <div className={styles.miniActions}>
                                                    {getStatusBadge(app.status)}
                                                    <Link
                                                        href={`/evaluacion?id=${app.id}`}
                                                        className={styles.miniLink}
                                                    >
                                                        →
                                                    </Link>
                                                </div>
                                            </div>
                                        ))}
                                </div>
                            </div>
                        ))}
                </div>
            )}
        </div>
    )
}
