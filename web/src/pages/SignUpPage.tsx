import { useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Eye, EyeOff } from 'lucide-react';
import { useAuth } from '../state/AuthContext';
import { AuthShell } from '../components/AuthShell';
import { GradientButton, GoogleSignInButton, OrDivider, TextField } from '../components/ui';

export default function SignUpPage() {
  const { signUp, signInWithGoogle } = useAuth();
  const navigate = useNavigate();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (password !== confirm) {
      setError('Passwords do not match.');
      return;
    }
    setLoading(true);
    try {
      const { needsConfirmation } = await signUp(email, password, name);
      if (needsConfirmation) {
        navigate('/confirm-email', { state: { email } });
      }
      // Otherwise the RootGate will redirect automatically once the session appears.
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
    <AuthShell title="Join ESCAPE" subtitle="Start tracking focus, goals, and training today.">
      {error && <p className="rounded-md bg-orange-soft px-3 py-2 text-sm text-orange">{error}</p>}
      <form onSubmit={handleSubmit} className="flex flex-col gap-4">
        <TextField label="Name" required value={name} onChange={(e) => setName(e.target.value)} />
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
            autoComplete="new-password"
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
        <TextField
          label="Confirm Password"
          type={showPassword ? 'text' : 'password'}
          required
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
        />
        <GradientButton label={loading ? 'Creating account…' : 'Create Account'} type="submit" disabled={loading} />
      </form>
      <OrDivider />
      <GoogleSignInButton label="Sign up with Google" onClick={handleGoogle} disabled={loading} />
      <p className="text-center text-sm text-on-surface-variant">
        Already have an account?{' '}
        <Link to="/" className="font-semibold text-cyan-deep">
          Sign In
        </Link>
      </p>
    </AuthShell>
  );
}
