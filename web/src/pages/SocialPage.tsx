import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Flame, ThumbsUp, UserPlus, QrCode, Copy, Zap, Dumbbell, Trophy } from 'lucide-react';
import { useAppStore } from '../state/AppStore';
import { AppCard, GradientAvatar, GradientButton, Modal, TextField } from '../components/ui';
import type { ActivityItem } from '../types/models';

function timeAgo(iso: string): string {
  const diffMs = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diffMs / 60_000);
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

function activityIcon(type: ActivityItem['type']) {
  if (type === 'workout') return Dumbbell;
  if (type === 'focus') return Zap;
  if (type === 'streak') return Flame;
  return Trophy;
}

export default function SocialPage() {
  const state = useAppStore();
  const navigate = useNavigate();
  const [showAdd, setShowAdd] = useState(false);
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  async function handleConnect() {
    setError(null);
    setSubmitting(true);
    try {
      const friend = await state.addFriendByCode(code);
      setShowAdd(false);
      setCode('');
      setToast(`Connected with ${friend.name}!`);
      setTimeout(() => setToast(null), 3500);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong.');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="mx-auto w-full max-w-2xl px-6 py-6">
      <h1 className="mb-6 text-2xl font-extrabold tracking-tight">Community</h1>

      {toast && (
        <div className="mb-4 rounded-md bg-cyan px-4 py-2.5 text-sm font-semibold text-white">{toast}</div>
      )}

      {state.myFriendCode && (
        <AppCard
          className="mb-6 !border-transparent !bg-cyan-soft"
          onClick={() => {
            navigator.clipboard?.writeText(state.myFriendCode!);
            setToast('Code copied — share it with a friend!');
            setTimeout(() => setToast(null), 3000);
          }}
        >
          <div className="flex items-center gap-3">
            <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-md bg-gradient-to-br from-cyan to-cyan-deep text-white">
              <QrCode size={20} />
            </span>
            <div className="flex-1">
              <p className="text-xs font-bold text-cyan-deep">Your Friend Code</p>
              <p className="text-xl font-extrabold tracking-widest">{state.myFriendCode}</p>
            </div>
            <Copy size={18} className="text-cyan-deep" />
          </div>
        </AppCard>
      )}

      <h2 className="mb-3 text-lg font-bold">Friends</h2>
      {state.friends.length === 0 ? (
        <p className="mb-6 text-sm text-on-surface-variant">
          No friends connected yet — share your code above to get started.
        </p>
      ) : (
        <div className="mb-6 flex gap-4 overflow-x-auto pb-1">
          {state.friends.map((f) => (
            <button
              key={f.id}
              onClick={() => navigate(`/friend/${f.id}`)}
              className="flex w-16 shrink-0 flex-col items-center gap-1.5"
            >
              <div className="relative">
                <GradientAvatar name={f.name} size={56} seed={f.avatarSeed} />
                {f.currentStreak > 0 && (
                  <span className="absolute -bottom-1 -right-1 flex items-center gap-0.5 rounded-full border-2 border-surface bg-amber px-1.5 py-0.5 text-[9px] font-extrabold text-white">
                    <Flame size={9} />
                    {f.currentStreak}
                  </span>
                )}
              </div>
              <span className="w-full truncate text-center text-[11px] font-semibold">{f.name.split(' ')[0]}</span>
            </button>
          ))}
        </div>
      )}

      <h2 className="mb-3 text-lg font-bold">Activity</h2>
      {state.activity.length === 0 ? (
        <p className="py-6 text-center text-sm text-on-surface-variant">
          No activity yet — connect friends to see their progress.
        </p>
      ) : (
        <div className="flex flex-col gap-2.5">
          {state.activity.map((item) => {
            const Icon = activityIcon(item.type);
            return (
              <AppCard key={item.id}>
                <div className="flex items-start gap-3">
                  <button onClick={() => navigate(`/friend/${item.friendId}`)}>
                    <GradientAvatar name={item.friendName} size={40} seed={item.avatarSeed} />
                  </button>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm">
                      <span className="font-extrabold">{item.friendName}</span> {item.message}
                    </p>
                    <div className="mt-1.5 flex items-center gap-1.5 text-xs">
                      <Icon size={13} className="text-cyan" />
                      <span className="font-bold text-cyan">{item.statLabel}</span>
                      <span className="text-on-surface-variant">· {timeAgo(item.timestamp)}</span>
                    </div>
                  </div>
                  <button
                    onClick={() => state.toggleKudos(item.id)}
                    className="flex shrink-0 flex-col items-center gap-0.5"
                  >
                    <ThumbsUp size={20} className={item.kudosGiven ? 'text-cyan' : 'text-on-surface-variant'} />
                    <span className={`text-[11px] font-bold ${item.kudosGiven ? 'text-cyan' : 'text-on-surface-variant'}`}>
                      {item.kudos}
                    </span>
                  </button>
                </div>
              </AppCard>
            );
          })}
        </div>
      )}

      <button
        onClick={() => setShowAdd(true)}
        className="fixed bottom-24 right-6 flex h-14 w-14 items-center justify-center rounded-full bg-cyan text-white shadow-lg shadow-cyan/40 md:bottom-8"
      >
        <UserPlus size={22} />
      </button>

      <Modal open={showAdd} onClose={() => setShowAdd(false)} title="Connect a Friend">
        <p className="text-sm text-on-surface-variant">
          Enter your friend's ESCAPE code to connect — they can find theirs at the top of this screen.
        </p>
        {error && <p className="rounded-md bg-orange-soft px-3 py-2 text-sm text-orange">{error}</p>}
        <TextField
          label="Friend code"
          value={code}
          onChange={(e) => setCode(e.target.value.toUpperCase())}
          autoFocus
        />
        <GradientButton label={submitting ? 'Connecting…' : 'Connect'} onClick={handleConnect} disabled={submitting} />
      </Modal>
    </div>
  );
}
