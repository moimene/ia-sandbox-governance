import Link from 'next/link'
import styles from './page.module.css'

export default function Home() {
  return (
    <>
      {/* Hero Section */}
      <section className={styles.hero}>
        <div className="container">
          <h1>Sandbox de Inteligencia Artificial de España</h1>
          <p className={styles.heroSubtitle}>
            Sistema de preevaluación para validar el cumplimiento normativo de tu sistema de IA
            según el RD 817/2023 y el Reglamento (UE) 2024/1689.
          </p>
          <div className={styles.heroActions}>
            <Link href="/evaluacion" className="btn btn-primary">
              Iniciar Evaluación
            </Link>
            <Link href="/info" className="btn btn-outline">
              Más Información
            </Link>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className={styles.features}>
        <div className="container">
          <h2>¿Qué puedes hacer?</h2>
          <div className={styles.featuresGrid}>
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>📋</div>
              <h3>Autodiagnóstico</h3>
              <p>
                Evalúa el nivel de madurez de tu sistema de IA según los 8 niveles
                definidos en la Guía 16 de AESIA.
              </p>
            </div>
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>🎯</div>
              <h3>Plan de Adaptación</h3>
              <p>
                Obtén automáticamente el plan de adaptación recomendado
                basado en tu nivel de madurez actual.
              </p>
            </div>
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>📄</div>
              <h3>Exportación Excel</h3>
              <p>
                Genera un informe completo en Excel con 9 pestañas
                listo para presentar al Sandbox.
              </p>
            </div>
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>🤖</div>
              <h3>Asistente Normativo</h3>
              <p>
                Consulta dudas sobre la normativa aplicable con nuestro
                asistente basado en las guías oficiales.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className={styles.cta}>
        <div className="container">
          <h2>¿Listo para evaluar tu sistema de IA?</h2>
          <p>Comienza ahora y obtén un diagnóstico completo de cumplimiento.</p>
          <Link href="/evaluacion" className="btn btn-success">
            Comenzar Evaluación Gratuita
          </Link>
        </div>
      </section>
    </>
  )
}
