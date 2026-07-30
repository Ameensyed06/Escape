import { useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { MailCheck } from 'lucide-react';
import { useAuth } from '../state/AuthContext';
import { AuthShell } from '../components/AuthShell';
import { GradientButton, TextField } from '../components/ui';

export default function ForgotPasswordPage() {
  const { sendPasswordResetEmail } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [sent, setSent] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await sendPasswordResetEmail(email);
      setSent(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  if (sent) {
    return (
      <AuthShell title="Check your email" subtitle="">
        <div className="flex h-20 w-20 items-center justify-center self-center rounded-full bg-gradient-to-br from-cyan to-cyan-deep text-white">
          <MailCheck size={36} />
        </div>
        <p className="text-center text-sm text-on-surface-variant">
          We've sent a password reset link to <span className="font-bold text-on-surface">{email}</span>. Open
          it on this device to set a new password.
        </p>
        <GradientButton label="Back to Sign In" onClick={() => navigate('/')} />
      </AuthShell>
    );
  }

  return (
    <AuthShell title="Forgot your password?" subtitle="Enter the email on your account and we'll send you a reset link.">
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
        <GradientButton label={loading ? 'Sending…' : 'Send Reset Link'} type="submit" disabled={loading} />
      </form>
      <Link to="/" className="text-center text-sm font-semibold text-cyan-deep">
        Back to Sign In
      </Link>
    </AuthShell>
  );
}
