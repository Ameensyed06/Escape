import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Plus, Search, ShieldCheck } from 'lucide-react';
import { useAppStore } from '../state/AppStore';
import { AppCard, GradientButton, Modal, Switch, TextField } from '../components/ui';
import { iconForKey, appIconKeys } from '../lib/iconMap';
import { formatMinutesLabel } from '../lib/dateUtils';

export default function BlockerPage() {
  const state = useAppStore();
  const navigate = useNavigate();
  const [query, setQuery] = useState('');
  const [showAdd, setShowAdd] = useState(false);
  const [name, setName] = useState('');
  const [icon, setIcon] = useState(appIconKeys[0]);

  const apps = state.blockedApps.filter((a) => a.name.toLowerCase().includes(query.toLowerCase()));

  return (
    <div className="mx-auto w-full max-w-2xl px-6 py-6">
      <div className="mb-4 flex items-center gap-3">
        <button onClick={() => navigate(-1)} className="text-on-surface-variant">
          <ArrowLeft size={20} />
        </button>
        <h1 className="text-2xl font-extrabold tracking-tight">App Blocker</h1>
      </div>

      <div className="mb-6 rounded-xl bg-gradient-to-br from-orange to-orange-deep p-5 text-white shadow-lg shadow-orange/25">
        <div className="mb-2.5 flex items-center gap-1.5 text-white/80">
          <ShieldCheck size={18} />
          <span className="text-sm font-bold">Reclaimed Focus Time</span>
        </div>
        <div className="text-3xl font-extrabold">{formatMinutesLabel(state.reclaimedMinutesToday)}</div>
        <p className="mt-1 text-sm text-white/70">
          {apps.filter((a) => a.blocked).length} apps blocked today
        </p>
      </div>

      <div className="relative mb-4">
        <Search size={18} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-on-surface-variant" />
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search apps"
          className="w-full rounded-pill border border-outline bg-surface py-2.5 pl-10 pr-4 text-sm outline-none focus:border-orange"
        />
      </div>

      <div className="mb-4 flex flex-col gap-2.5">
        {apps.map((app) => {
          const Icon = iconForKey(app.iconKey);
          return (
            <AppCard key={app.id}>
              <div className="flex items-center gap-3">
                <span
                  className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-md ${
                    app.blocked ? 'bg-orange-soft text-orange' : 'bg-background text-on-surface-variant'
                  }`}
                >
                  <Icon size={18} />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-bold">{app.name}</p>
                  {app.minutesSavedToday > 0 && (
                    <p className="text-xs text-on-surface-variant">
                      {formatMinutesLabel(app.minutesSavedToday)} saved today
                    </p>
                  )}
                </div>
                <Switch checked={app.blocked} onChange={() => state.toggleAppBlocked(app.id)} />
              </div>
            </AppCard>
          );
        })}
        {apps.length === 0 && <p className="py-8 text-center text-sm text-on-surface-variant">No apps found</p>}
      </div>

      <button
        onClick={() => setShowAdd(true)}
        className="fixed bottom-24 right-6 flex h-14 w-14 items-center justify-center rounded-full bg-orange text-white shadow-lg shadow-orange/40 md:bottom-8"
      >
        <Plus size={24} />
      </button>

      <Modal open={showAdd} onClose={() => setShowAdd(false)} title="Block a New App">
        <TextField label="App name" value={name} onChange={(e) => setName(e.target.value)} autoFocus />
        <div className="flex flex-wrap gap-2">
          {appIconKeys.map((key) => {
            const Icon = iconForKey(key);
            const selected = key === icon;
            return (
              <button
                key={key}
                onClick={() => setIcon(key)}
                className={`flex h-11 w-11 items-center justify-center rounded-md border transition ${
                  selected ? 'border-orange bg-orange-soft text-orange' : 'border-outline text-on-surface-variant'
                }`}
              >
                <Icon size={18} />
              </button>
            );
          })}
        </div>
        <GradientButton
          label="Add & Block"
          gradient="from-orange to-orange-deep"
          onClick={() => {
            if (!name.trim()) return;
            state.addBlockedApp(name.trim(), icon);
            setName('');
            setShowAdd(false);
          }}
        />
      </Modal>
    </div>
  );
}
