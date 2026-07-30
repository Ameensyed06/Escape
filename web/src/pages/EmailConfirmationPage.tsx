import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { MailCheck, CheckCircle2 } from 'lucide-react';
import { useAuth } from '../state/AuthContext';
import { AuthShell } from '../components/AuthShell';
import { GradientButton, OutlineButton, Pill } from '../components/ui';

export default function EmailConfirmationPage() {
  const { resendConfirmationEmail } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const email = (location.state as { email?: string } | null)?.email ?? '';

  const [resending, setResending] = useState(false);
  const [resent, setResent] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleResend() {
    if (!email) return;
    setResending(true);
    setError(null);
    try {
      await resendConfirmationEmail(email);
      setResent(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong.');
    } finally {
      setResending(false);
    }
  }

  return (
    <AuthShell title="Check your email" subtitle="">
      <div className="flex h-20 w-20 items-center justify-center self-center rounded-full bg-gradient-to-br from-cyan to-cyan-deep text-white">
        <MailCheck size={36} />
      </div>
      <p className="text-center text-sm text-on-surface-variant">
        We've sent a confirmation link to{' '}
        {email ? <span className="font-bold text-on-surface">{email}</span> : 'your email'}. Tap the link to
        activate your account, then come back and sign in.
      </p>
      {error && <p className="rounded-md bg-orange-soft px-3 py-2 text-sm text-orange">{error}</p>}
      {resent && (
        <Pill label="Email resent" icon={<CheckCircle2 size={14} />} color="bg-cyan-soft" textColor="text-cyan-deep" />
      )}
      <OutlineButton label={resending ? 'Sending…' : 'Resend Email'} onClick={handleResend} disabled={resending || !email} />
      <GradientButton label="Back to Sign In" onClick={() => navigate('/')} />
    </AuthShell>
  );
}
