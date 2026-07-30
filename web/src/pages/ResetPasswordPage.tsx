import { useState, type FormEvent } from 'react';
import { useAuth } from '../state/AuthContext';
import { AuthShell } from '../components/AuthShell';
import { GradientButton, TextField } from '../components/ui';

export default function ResetPasswordPage() {
  const { updatePassword, clearPasswordRecovery } = useAuth();
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
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
      await updatePassword(password);
      clearPasswordRecovery();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong. Please try again.');
      setLoading(false);
    }
  }

  return (
    <AuthShell title="Set a new password" subtitle="Choose a new password for your account.">
      {error && <p className="rounded-md bg-orange-soft px-3 py-2 text-sm text-orange">{error}</p>}
      <form onSubmit={handleSubmit} className="flex flex-col gap-4">
        <TextField
          label="New Password"
          type="password"
          autoComplete="new-password"
          required
          minLength={6}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        <TextField
          label="Confirm New Password"
          type="password"
          required
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
        />
        <GradientButton label={loading ? 'Updating…' : 'Update Password'} type="submit" disabled={loading} />
      </form>
    </AuthShell>
  );
}
