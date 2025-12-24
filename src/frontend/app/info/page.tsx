'use client'

import Link from 'next/link'
import styles from './page.module.css'

export default function InfoPage() {
    return (
        <div className={styles.pageContainer}>
            {/* Hero Section */}
            <section className={styles.hero}>
                <div className="container">
                    <h1 style={{ color: '#004438' }}>¿Qué es el Sandbox de IA de España?</h1>
                    <p className={styles.heroSubtitle} style={{ color: '#004438' }}>
                        Un entorno controlado para probar sistemas de Inteligencia Artificial
                        de alto riesgo bajo supervisión regulatoria
                    </p>
                </div>
            </section>



            <div className="container" style={{ padding: 'var(--spacing-2xl) 0' }}>
                {/* What is it */}
                <section className={styles.section}>
                    <h2>🎯 Objetivo del Sandbox</h2>
                    <div className={styles.contentGrid}>
                        <div className={styles.contentCard}>
                            <h3>Para Empresas</h3>
                            <p>
                                Permite a proveedores y responsables de despliegue de sistemas de IA
                                de alto riesgo probar sus innovaciones en un entorno regulado,
                                recibiendo orientación de AESIA y preparándose para el cumplimiento
                                del Reglamento de IA (RIA).
                            </p>
                        </div>
                        <div className={styles.contentCard}>
                            <h3>Para el Regulador</h3>
                            <p>
                                Permite a AESIA y la Comisión Europea aprender sobre tecnologías
                                emergentes, identificar riesgos y desarrollar mejores prácticas
                                regulatorias antes de la plena aplicación del RIA.
                            </p>
                        </div>
                    </div>
                </section>

                {/* Who can participate */}
                <section className={styles.section}>
                    <h2>👥 ¿Quién puede participar?</h2>
                    <div className={styles.eligibilityGrid}>
                        <div className={styles.eligibilityItem}>
                            <span className={styles.checkIcon}>✓</span>
                            <div>
                                <strong>Proveedores de IA</strong>
                                <p>Empresas que desarrollan sistemas de IA de alto riesgo</p>
                            </div>
                        </div>
                        <div className={styles.eligibilityItem}>
                            <span className={styles.checkIcon}>✓</span>
                            <div>
                                <strong>Responsables del despliegue</strong>
                                <p>Organizaciones que implementan sistemas de IA de terceros</p>
                            </div>
                        </div>
                        <div className={styles.eligibilityItem}>
                            <span className={styles.checkIcon}>✓</span>
                            <div>
                                <strong>Startups e innovadores</strong>
                                <p>Emprendedores con soluciones de IA novedosas</p>
                            </div>
                        </div>
                        <div className={styles.eligibilityItem}>
                            <span className={styles.checkIcon}>✓</span>
                            <div>
                                <strong>Administraciones públicas</strong>
                                <p>Entidades del sector público con proyectos de IA</p>
                            </div>
                        </div>
                    </div>
                </section>

                {/* Process */}
                <section className={styles.section}>
                    <h2>📋 Proceso de Participación</h2>
                    <div className={styles.timeline}>
                        <div className={styles.timelineItem}>
                            <div className={styles.timelineNumber}>1</div>
                            <div className={styles.timelineContent}>
                                <h4>Preevaluación</h4>
                                <p>
                                    Complete el autodiagnóstico con esta herramienta para evaluar
                                    el nivel de madurez de su sistema frente a los 12 requisitos del RIA.
                                </p>
                            </div>
                        </div>
                        <div className={styles.timelineItem}>
                            <div className={styles.timelineNumber}>2</div>
                            <div className={styles.timelineContent}>
                                <h4>Solicitud</h4>
                                <p>
                                    Presente su solicitud de admisión al Sandbox junto con la
                                    documentación requerida y los resultados de la preevaluación.
                                </p>
                            </div>
                        </div>
                        <div className={styles.timelineItem}>
                            <div className={styles.timelineNumber}>3</div>
                            <div className={styles.timelineContent}>
                                <h4>Evaluación</h4>
                                <p>
                                    AESIA evalúa la solicitud según criterios de elegibilidad,
                                    innovación, impacto y viabilidad del proyecto.
                                </p>
                            </div>
                        </div>
                        <div className={styles.timelineItem}>
                            <div className={styles.timelineNumber}>4</div>
                            <div className={styles.timelineContent}>
                                <h4>Participación</h4>
                                <p>
                                    Los proyectos seleccionados entran en el Sandbox por un período
                                    limitado con supervisión y apoyo de AESIA.
                                </p>
                            </div>
                        </div>
                        <div className={styles.timelineItem}>
                            <div className={styles.timelineNumber}>5</div>
                            <div className={styles.timelineContent}>
                                <h4>Informe final</h4>
                                <p>
                                    Al concluir, recibirá un informe con recomendaciones para
                                    la puesta en marcha conforme al RIA.
                                </p>
                            </div>
                        </div>
                    </div>
                </section>

                {/* Normative Framework */}
                <section className={styles.section}>
                    <h2>⚖️ Marco Normativo</h2>
                    <div className={styles.normativeGrid}>
                        <div className={styles.normativeCard}>
                            <h4>Reglamento (UE) 2024/1689</h4>
                            <p>
                                Reglamento de Inteligencia Artificial (RIA) - El marco legal europeo
                                para sistemas de IA, incluyendo requisitos para sistemas de alto riesgo.
                            </p>
                            <span className={styles.tag}>EU AI Act</span>
                        </div>
                        <div className={styles.normativeCard}>
                            <h4>Real Decreto 817/2023</h4>
                            <p>
                                Establece el entorno controlado de pruebas (Sandbox) para sistemas
                                de IA en España, regulando su funcionamiento y procedimientos.
                            </p>
                            <span className={styles.tag}>España</span>
                        </div>
                        <div className={styles.normativeCard}>
                            <h4>Guías AESIA 1-16</h4>
                            <p>
                                Conjunto de guías prácticas publicadas por AESIA para orientar
                                a las organizaciones en el cumplimiento del RIA. La Guía 16
                                contiene los checklists de autoevaluación.
                            </p>
                            <span className={styles.tag}>Orientación</span>
                        </div>
                    </div>
                </section>

                {/* CTA */}
                <section className={styles.ctaSection}>
                    <h2>¿Listo para evaluar su sistema?</h2>
                    <p>
                        Utilice nuestra herramienta de preevaluación para conocer el estado
                        de cumplimiento de su sistema de IA.
                    </p>
                    <div className={styles.ctaButtons}>
                        <Link href="/evaluacion" className="btn btn-primary btn-lg">
                            Comenzar Evaluación
                        </Link>
                        <Link href="/faq" className="btn btn-outline btn-lg">
                            Preguntas Frecuentes
                        </Link>
                    </div>
                </section>
            </div>
        </div>
    )
}
