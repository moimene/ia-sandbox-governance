'use client'

import { createContext, useContext, useEffect, useState, ReactNode } from 'react'
import { User, Session } from '@supabase/supabase-js'
import { supabase } from './supabase'

interface AuthContextType {
    user: User | null
    session: Session | null
    loading: boolean
    userRole: string | null
    userOrgs: Array<{ id: string; name: string; role: string }>
    signIn: (email: string, password: string) => Promise<{ error: Error | null }>
    signUp: (email: string, password: string) => Promise<{ error: Error | null }>
    createOrganization: (orgName: string) => Promise<{ error: Error | null; orgId?: string }>
    signOut: () => Promise<void>
    refreshUser: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
    const [user, setUser] = useState<User | null>(null)
    const [session, setSession] = useState<Session | null>(null)
    const [loading, setLoading] = useState(true)
    const [userRole, setUserRole] = useState<string | null>(null)
    const [userOrgs, setUserOrgs] = useState<Array<{ id: string; name: string; role: string }>>([])

    useEffect(() => {
        // Get initial session
        supabase.auth.getSession().then(({ data: { session } }) => {
            setSession(session)
            setUser(session?.user ?? null)
            if (session?.user) {
                loadUserOrgs(session.user.id)
            }
            setLoading(false)
        })

        // Listen for auth changes
        const { data: { subscription } } = supabase.auth.onAuthStateChange(
            async (event, session) => {
                setSession(session)
                setUser(session?.user ?? null)
                if (session?.user) {
                    await loadUserOrgs(session.user.id)
                } else {
                    setUserOrgs([])
                    setUserRole(null)
                }
                setLoading(false)
            }
        )

        return () => subscription.unsubscribe()
    }, [])

    const loadUserOrgs = async (userId: string) => {
        const { data, error } = await supabase
            .from('org_members')
            .select(`
        role,
        organizations (
          id,
          name
        )
      `)
            .eq('user_id', userId)

        if (error) {
            console.error('Error loading user orgs:', error)
            return
        }

        if (data && data.length > 0) {
            const orgs = data.map((m: any) => ({
                id: m.organizations.id,
                name: m.organizations.name,
                role: m.role
            }))
            setUserOrgs(orgs)

            // Set primary role (highest privilege)
            if (orgs.some(o => o.role === 'ADMIN_REVIEWER')) {
                setUserRole('ADMIN_REVIEWER')
            } else if (orgs.some(o => o.role === 'ADVISOR')) {
                setUserRole('ADVISOR')
            } else {
                setUserRole('ORG_MEMBER')
            }
        }
    }

    const signIn = async (email: string, password: string) => {
        const { error } = await supabase.auth.signInWithPassword({
            email,
            password
        })
        return { error: error as Error | null }
    }

    const signUp = async (email: string, password: string) => {
        const { error } = await supabase.auth.signUp({
            email,
            password
        })
        return { error: error as Error | null }
    }

    const createOrganization = async (orgName: string) => {
        if (!user) {
            return { error: new Error('No hay usuario autenticado') }
        }

        // 1. Create the organization
        const { data: orgData, error: orgError } = await supabase
            .from('organizations')
            .insert({ name: orgName })
            .select()
            .single()

        if (orgError || !orgData) {
            return { error: orgError as Error | null }
        }

        // 2. Add user as ORG_MEMBER
        const { error: memberError } = await supabase
            .from('org_members')
            .insert({
                org_id: orgData.id,
                user_id: user.id,
                role: 'ORG_MEMBER',
                is_primary: true,
                accepted_at: new Date().toISOString()
            })

        if (memberError) {
            return { error: memberError as Error | null }
        }

        // 3. Refresh user orgs
        await loadUserOrgs(user.id)

        return { error: null, orgId: orgData.id }
    }

    const signOut = async () => {
        await supabase.auth.signOut()
        setUser(null)
        setSession(null)
        setUserOrgs([])
        setUserRole(null)
    }

    const refreshUser = async () => {
        if (user) {
            await loadUserOrgs(user.id)
        }
    }

    return (
        <AuthContext.Provider value={{
            user,
            session,
            loading,
            userRole,
            userOrgs,
            signIn,
            signUp,
            signOut,
            refreshUser,
            createOrganization
        }}>
            {children}
        </AuthContext.Provider>
    )
}

export function useAuth() {
    const context = useContext(AuthContext)
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider')
    }
    return context
}

export function useRequireAuth(redirectTo = '/auth/login') {
    const { user, loading } = useAuth()

    useEffect(() => {
        if (!loading && !user) {
            window.location.href = redirectTo
        }
    }, [user, loading, redirectTo])

    return { user, loading }
}
