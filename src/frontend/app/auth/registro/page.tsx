'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useAuth } from '../../../lib/auth'
import styles from '../login/page.module.css'

export default function RegistroPage() {
    const { signUp } = useAuth()

    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [confirmPassword, setConfirmPassword] = useState('')
    const [error, setError] = useState('')
    const [success, setSuccess] = useState(false)
    const [loading, setLoading] = useState(false)

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setError('')

        // Validations
        if (password !== confirmPassword) {
            setError('Las contraseñas no coinciden')
            return
        }

        if (password.length < 6) {
            setError('La contraseña debe tener al menos 6 caracteres')
            return
        }

        setLoading(true)

        const { error } = await signUp(email, password)

        if (error) {
            setError(error.message)
            setLoading(false)
        } else {
            setSuccess(true)
        }
    }

    if (success) {
        return (
            <div className={styles.authContainer}>
                <div className={styles.authCard}>
                    <div className={styles.authHeader}>
                        <h1>✅ Registro Completado</h1>
                        <p>Revisa tu email para confirmar tu cuenta</p>
                    </div>

                    <div className={styles.successMessage}>
                        Hemos enviado un email de confirmación a <strong>{email}</strong>.
                        Por favor, haz clic en el enlace del email para activar tu cuenta.
                    </div>

                    <div style={{ marginTop: 'var(--spacing-xl)', textAlign: 'center' }}>
                        <Link href="/auth/login" className="btn btn-primary">
                            Ir a Iniciar Sesión
                        </Link>
                    </div>
                </div>
            </div>
        )
    }

    return (
        <div className={styles.authContainer}>
            <div className={styles.authCard}>
                <div className={styles.authHeader}>
                    <h1>Crear Cuenta</h1>
                    <p>Regístrate para acceder al sistema de preevaluación</p>
                </div>

                <form onSubmit={handleSubmit} className={styles.authForm}>
                    {error && (
                        <div className={styles.errorMessage}>
                            {error}
                        </div>
                    )}

                    <div className="form-group">
                        <label className="form-label">Email corporativo *</label>
                        <input
                            type="email"
                            className="form-input"
                            value={email}
                            onChange={e => setEmail(e.target.value)}
                            placeholder="tu@empresa.com"
                            required
                        />
                    </div>

                    <div className="form-group">
                        <label className="form-label">Contraseña *</label>
                        <input
                            type="password"
                            className="form-input"
                            value={password}
                            onChange={e => setPassword(e.target.value)}
                            placeholder="Mínimo 6 caracteres"
                            required
                            minLength={6}
                        />
                    </div>

                    <div className="form-group">
                        <label className="form-label">Confirmar Contraseña *</label>
                        <input
                            type="password"
                            className="form-input"
                            value={confirmPassword}
                            onChange={e => setConfirmPassword(e.target.value)}
                            placeholder="Repite la contraseña"
                            required
                        />
                    </div>

                    <button
                        type="submit"
                        className="btn btn-primary btn-full"
                        disabled={loading}
                    >
                        {loading ? 'Creando cuenta...' : 'Crear Cuenta'}
                    </button>

                    <p style={{ fontSize: 'var(--font-size-sm)', color: 'var(--color-gray-600)', textAlign: 'center', marginTop: 'var(--spacing-md)' }}>
                        Podrás crear o unirte a una organización después de iniciar sesión
                    </p>
                </form>

                <div className={styles.authFooter}>
                    <p>
                        ¿Ya tienes cuenta?{' '}
                        <Link href="/auth/login">Inicia sesión aquí</Link>
                    </p>
                </div>
            </div>
        </div>
    )
}

