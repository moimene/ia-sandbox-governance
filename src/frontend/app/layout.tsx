'use client'

import { AuthProvider, useAuth } from '../lib/auth'
import '../styles/globals.css'
import styles from '../styles/layout.module.css'
import Link from 'next/link'

function Navbar() {
    const { user, userRole, signOut, loading } = useAuth()

    return (
        <header className={styles.header}>
            <div className="container">
                <nav className={styles.nav}>
                    <Link href="/" className={styles.logo}>
                        <span className={styles.logoText}>IA Sandbox</span>
                    </Link>

                    <div className={styles.navLinks}>
                        {user ? (
                            <>
                                <Link href="/mis-evaluaciones">Mis Evaluaciones</Link>
                                <Link href="/evaluacion">Nueva Evaluación</Link>
                                {userRole === 'ADMIN_REVIEWER' && (
                                    <Link href="/admin">Admin</Link>
                                )}
                                <Link href="/info">Información</Link>
                                <button
                                    onClick={() => signOut()}
                                    className={styles.logoutBtn}
                                >
                                    Salir
                                </button>
                            </>
                        ) : (
                            <>
                                <Link href="/info">Información</Link>
                                <Link href="/auth/login" className={styles.loginBtn}>
                                    Acceder
                                </Link>
                            </>
                        )}
                    </div>
                </nav>
            </div>
        </header>
    )
}

export default function RootLayout({
    children,
}: {
    children: React.ReactNode
}) {
    return (
        <html lang="es">
            <head>
                <title>IA Sandbox - Sistema de Preevaluación</title>
                <meta name="description" content="Sistema de preevaluación para el Sandbox Español de Inteligencia Artificial. Evalúa el cumplimiento normativo según RD 817/2023 y Reglamento UE 2024/1689." />
                <link rel="preconnect" href="https://fonts.googleapis.com" />
                <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
                <link
                    href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700&display=swap"
                    rel="stylesheet"
                />
            </head>
            <body>
                <AuthProvider>
                    <Navbar />
                    <main>{children}</main>
                    <footer style={{
                        textAlign: 'center',
                        padding: '1rem',
                        fontSize: '0.75rem',
                        color: 'var(--color-text-secondary)',
                        borderTop: '1px solid var(--color-border)',
                        marginTop: '2rem'
                    }}>
                        <p>
                            ⚠️ <strong>Aviso Legal:</strong> Esta aplicación es una herramienta de apoyo y <strong>no garantiza conformidad oficial</strong> con el Reglamento de IA ni con los requisitos del Sandbox.
                            El uso de esta herramienta no sustituye el asesoramiento legal ni la validación por parte de la autoridad competente (SEDIA/AESIA).
                        </p>
                    </footer>
                </AuthProvider>
            </body>
        </html>
    )
}
