'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth, useRequireAuth } from '../../lib/auth'
import styles from '../auth/login/page.module.css'

export default function OnboardingPage() {
    useRequireAuth()
    const router = useRouter()
    const { user, userOrgs, createOrganization, loading: authLoading } = useAuth()

    const [orgName, setOrgName] = useState('')
    const [error, setError] = useState('')
    const [loading, setLoading] = useState(false)

    // If user already has orgs, redirect to dashboard
    if (!authLoading && userOrgs.length > 0) {
        router.push('/mis-evaluaciones')
        return null
    }

    const handleCreateOrg = async (e: React.FormEvent) => {
        e.preventDefault()
        setError('')

        if (!orgName.trim()) {
            setError('El nombre de la organización es obligatorio')
            return
        }

        setLoading(true)

        const { error } = await createOrganization(orgName)

        if (error) {
            setError(error.message)
            setLoading(false)
        } else {
            router.push('/mis-evaluaciones')
        }
    }

    if (authLoading) {
        return (
            <div className={styles.authContainer}>
                <div className={styles.authCard}>
                    <p>Cargando...</p>
                </div>
            </div>
        )
    }

    return (
        <div className={styles.authContainer}>
            <div className={styles.authCard}>
                <div className={styles.authHeader}>
                    <h1>¡Bienvenido! 👋</h1>
                    <p>Para empezar, crea o únete a una organización</p>
                </div>

                <form onSubmit={handleCreateOrg} className={styles.authForm}>
                    {error && (
                        <div className={styles.errorMessage}>
                            {error}
                        </div>
                    )}

                    <div className="form-group">
                        <label className="form-label">Nombre de tu Organización</label>
                        <input
                            type="text"
                            className="form-input"
                            value={orgName}
                            onChange={e => setOrgName(e.target.value)}
                            placeholder="Ej: ACME Corp, Garrigues, Mi Startup..."
                            required
                        />
                        <small style={{ color: 'var(--color-gray-500)', fontSize: 'var(--font-size-xs)', marginTop: '4px', display: 'block' }}>
                            Podrás añadir más usuarios a tu organización después
                        </small>
                    </div>

                    <button
                        type="submit"
                        className="btn btn-primary btn-full"
                        disabled={loading}
                    >
                        {loading ? 'Creando organización...' : 'Crear Organización'}
                    </button>
                </form>

                <div style={{ marginTop: 'var(--spacing-xl)', padding: 'var(--spacing-md)', background: 'var(--color-gray-50)', borderRadius: 'var(--radius-md)', textAlign: 'center' }}>
                    <p style={{ fontSize: 'var(--font-size-sm)', color: 'var(--color-gray-600)', margin: 0 }}>
                        ¿Ya te han invitado a una organización?<br />
                        <span style={{ color: 'var(--color-gray-500)' }}>Las invitaciones aparecerán automáticamente en tu bandeja de entrada</span>
                    </p>
                </div>
            </div>
        </div>
    )
}
