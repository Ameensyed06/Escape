import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import type { Session, User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';

interface AuthContextValue {
  ready: boolean;
  session: Session | null;
  user: User | null;
  signedIn: boolean;
  displayName: string;
  email: string;
  passwordRecoveryPending: boolean;
  clearPasswordRecovery: () => void;
  signUp: (email: string, password: string, displayName: string) => Promise<{ needsConfirmation: boolean }>;
  signInWithPassword: (email: string, password: string) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  sendPasswordResetEmail: (email: string) => Promise<void>;
  updatePassword: (newPassword: string) => Promise<void>;
  resendConfirmationEmail: (email: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function nameFromUser(user: User | null): string {
  if (!user) return '';
  const meta = (user.user_metadata ?? {}) as Record<string, unknown>;
  const metaName = (meta.display_name as string) ?? (meta.full_name as string) ?? (meta.name as string);
  if (metaName && metaName.trim().length > 0) return metaName.trim();
  return (user.email ?? '').split('@')[0] ?? '';
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [ready, setReady] = useState(false);
  const [session, setSession] = useState<Session | null>(null);
  const [passwordRecoveryPending, setPasswordRecoveryPending] = useState(false);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setReady(true);
    });

    const { data: sub } = supabase.auth.onAuthStateChange((event, newSession) => {
      if (event === 'PASSWORD_RECOVERY') setPasswordRecoveryPending(true);
      setSession(newSession);
    });

    return () => sub.subscription.unsubscribe();
  }, []);

  const user = session?.user ?? null;

  const value: AuthContextValue = {
    ready,
    session,
    user,
    signedIn: !!user,
    displayName: nameFromUser(user),
    email: user?.email ?? '',
    passwordRecoveryPending,
    clearPasswordRecovery: () => setPasswordRecoveryPending(false),

    async signUp(email, password, displayName) {
      const redirectTo = `${window.location.origin}/`;
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: { data: { display_name: displayName }, emailRedirectTo: redirectTo },
      });
      if (error) throw error;
      return { needsConfirmation: !data.session };
    },

    async signInWithPassword(email, password) {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
    },

    async signInWithGoogle() {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: { redirectTo: `${window.location.origin}/` },
      });
      if (error) throw error;
    },

    async sendPasswordResetEmail(email) {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`,
      });
      if (error) throw error;
    },

    async updatePassword(newPassword) {
      const { error } = await supabase.auth.updateUser({ password: newPassword });
      if (error) throw error;
    },

    async resendConfirmationEmail(email) {
      const { error } = await supabase.auth.resend({ type: 'signup', email });
      if (error) throw error;
    },

    async signOut() {
      await supabase.auth.signOut();
    },
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
