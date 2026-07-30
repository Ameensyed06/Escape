import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Zap, Flame, Dumbbell, Trophy, ThumbsUp } from 'lucide-react';
import { useAppStore } from '../state/AppStore';
import { useAuth } from '../state/AuthContext';
import { setKudos } from '../lib/socialService';
import { AppCard, GradientAvatar, Pill } from '../components/ui';
import type { ActivityItem, Friend } from '../types/models';

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

export default function FriendDashboardPage() {
  const { friendId } = useParams<{ friendId: string }>();
  const navigate = useNavigate();
  const state = useAppStore();
  const { user } = useAuth();

  const [friend, setFriend] = useState<Friend | null>(null);
  const [activity, setActivity] = useState<ActivityItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!friendId) return;
    let cancelled = false;
    setLoading(true);
    Promise.all([state.friendProfile(friendId), state.friendActivity(friendId)]).then(([f, a]) => {
      if (cancelled) return;
      if (f) setFriend(f);
      setActivity(a);
      setLoading(false);
    });
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [friendId]);

  function handleToggleKudos(activityId: string) {
    setActivity((prev) =>
      prev.map((a) =>
        a.id === activityId ? { ...a, kudosGiven: !a.kudosGiven, kudos: a.kudos + (!a.kudosGiven ? 1 : -1) } : a,
      ),
    );
    if (!user) return;
    const item = activity.find((a) => a.id === activityId);
    const given = item ? !item.kudosGiven : true;
    setKudos(activityId, user.id, given).catch(() => {});
  }

  return (
    <div className="mx-auto w-full max-w-2xl px-6 py-6">
      <div className="mb-4 flex items-center gap-3">
        <button onClick={() => navigate(-1)} className="text-on-surface-variant">
          <ArrowLeft size={20} />
        </button>
        <h1 className="text-2xl font-extrabold tracking-tight">{friend?.name ?? 'Friend'}</h1>
      </div>

      {!friend ? (
        <p className="py-10 text-center text-sm text-on-surface-variant">
          {loading ? 'Loading…' : "Couldn't load this profile."}
        </p>
      ) : (
        <>
          <div className="mb-6 flex flex-col items-center gap-3">
            <GradientAvatar name={friend.name} size={88} seed={friend.avatarSeed} />
            <h2 className="text-xl font-extrabold">{friend.name}</h2>
            <Pill label={friend.rank} icon={<Trophy size={14} />} />
          </div>

          <h3 className="mb-3 text-lg font-bold">Progress</h3>
          <div className="mb-6 grid grid-cols-2 gap-2.5">
            <StatTile icon={Zap} color="text-cyan" bg="bg-cyan-soft" label="Focus Score" value={String(friend.focusScore)} />
            <StatTile icon={Flame} color="text-amber" bg="bg-amber-soft" label="Streak Days" value={String(friend.currentStreak)} />
            <StatTile icon={Dumbbell} color="text-orange" bg="bg-orange-soft" label="Workouts Done" value={String(friend.workoutsDone)} />
            <StatTile icon={Trophy} color="text-cyan-deep" bg="bg-cyan-soft" label="Rank" value={friend.rank} />
          </div>

          <h3 className="mb-3 text-lg font-bold">Recent Activity</h3>
          {activity.length === 0 ? (
            <p className="py-6 text-center text-sm text-on-surface-variant">No activity yet.</p>
          ) : (
            <div className="flex flex-col gap-2.5">
              {activity.map((item) => {
                const Icon = activityIcon(item.type);
                return (
                  <AppCard key={item.id}>
                    <div className="flex items-start gap-3">
                      <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-md bg-cyan-soft text-cyan">
                        <Icon size={17} />
                      </span>
                      <div className="min-w-0 flex-1">
                        <p className="text-sm font-bold">{item.message}</p>
                        <div className="mt-1 flex items-center gap-1.5 text-xs">
                          <span className="font-bold text-cyan">{item.statLabel}</span>
                          <span className="text-on-surface-variant">· {timeAgo(item.timestamp)}</span>
                        </div>
                      </div>
                      <button
                        onClick={() => handleToggleKudos(item.id)}
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
        </>
      )}
    </div>
  );
}

function StatTile({
  icon: Icon,
  color,
  bg,
  label,
  value,
}: {
  icon: typeof Zap;
  color: string;
  bg: string;
  label: string;
  value: string;
}) {
  return (
    <AppCard>
      <span className={`mb-2 flex h-8 w-8 items-center justify-center rounded-md ${bg} ${color}`}>
        <Icon size={16} />
      </span>
      <p className="truncate text-lg font-extrabold">{value}</p>
      <p className="text-[11px] text-on-surface-variant">{label}</p>
    </AppCard>
  );
}
