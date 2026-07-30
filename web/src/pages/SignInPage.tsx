import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { Eye, EyeOff } from 'lucide-react';
import { useAuth } from '../state/AuthContext';
import { AuthShell } from '../components/AuthShell';
import { GradientButton, GoogleSignInButton, OrDivider, TextField } from '../components/ui';

export default function SignInPage() {
  const { signInWithPassword, signInWithGoogle } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await signInWithPassword(email, password);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  async function handleGoogle() {
    setError(null);
    setLoading(true);
    try {
      await signInWithGoogle();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not start Google sign-in.');
      setLoading(false);
    }
  }

  return (
    <AuthShell title="ESCAPE" subtitle="Welcome back. Sign in to keep your streak alive.">
      {error && <p className="rounded-md bg-orange-soft px-3 py-2 text-sm text-orange">{error}</p>}
      <form onSubmit={handleSubmit} className="flex flex-col gap-4">
        <TextField
          label="Email"
          type="email"
          autoComplete="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
        <div className="relative">
          <TextField
            label="Password"
            type={showPassword ? 'text' : 'password'}
            autoComplete="current-password"
            required
            minLength={6}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
          <button
            type="button"
            onClick={() => setShowPassword((v) => !v)}
            className="absolute right-3 top-8 text-on-surface-variant"
          >
            {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
          </button>
        </div>
        <Link to="/forgot-password" className="self-end text-xs font-semibold text-cyan-deep">
          Forgot password?
        </Link>
        <GradientButton label={loading ? 'Signing in…' : 'Sign In'} type="submit" disabled={loading} />
      </form>
      <OrDivider />
      <GoogleSignInButton onClick={handleGoogle} disabled={loading} />
      <p className="text-center text-sm text-on-surface-variant">
        Don't have an account?{' '}
        <Link to="/sign-up" className="font-semibold text-cyan-deep">
          Sign Up
        </Link>
      </p>
    </AuthShell>
  );
}
