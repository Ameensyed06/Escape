import type { ButtonHTMLAttributes, ReactNode } from 'react';
import { X } from 'lucide-react';

// Shared visual building blocks — mirrors lib/widgets/common.dart.

/// Web analogue of Flutter's showModalBottomSheet — a centered dialog on
/// desktop, slides up from the bottom on small screens.
export function Modal({
  open,
  onClose,
  title,
  children,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
}) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 md:items-center" onClick={onClose}>
      <div
        className="w-full max-w-md rounded-t-xl bg-surface p-5 pb-7 md:rounded-xl md:pb-5"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-lg font-bold text-on-surface">{title}</h3>
          <button type="button" onClick={onClose} className="text-on-surface-variant">
            <X size={20} />
          </button>
        </div>
        <div className="flex flex-col gap-4">{children}</div>
      </div>
    </div>
  );
}

export function AppCard({
  children,
  className = '',
  onClick,
}: {
  children: ReactNode;
  className?: string;
  onClick?: () => void;
}) {
  const base = 'rounded-xl border border-outline bg-surface p-4 text-left';
  if (onClick) {
    return (
      <button
        type="button"
        onClick={onClick}
        className={`${base} w-full transition hover:border-cyan/40 hover:shadow-sm ${className}`}
      >
        {children}
      </button>
    );
  }
  return <div className={`${base} ${className}`}>{children}</div>;
}

const AVATAR_GRADIENTS = [
  'from-cyan to-cyan-deep',
  'from-amber to-amber-deep',
  'from-violet-500 to-violet-800',
  'from-pink-500 to-pink-800',
];

export function GradientAvatar({
  name,
  size = 44,
  seed = 0,
}: {
  name: string;
  size?: number;
  seed?: number;
}) {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  const initials =
    parts.length === 0
      ? '?'
      : parts.length === 1
        ? parts[0].slice(0, 2).toUpperCase()
        : (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  const gradient = AVATAR_GRADIENTS[seed % AVATAR_GRADIENTS.length];
  return (
    <div
      className={`flex shrink-0 items-center justify-center rounded-full bg-gradient-to-br font-extrabold text-white ${gradient}`}
      style={{ width: size, height: size, fontSize: size * 0.38 }}
    >
      {initials}
    </div>
  );
}

export function SectionHeader({ title, action }: { title: string; action?: ReactNode }) {
  return (
    <div className="flex items-center justify-between">
      <h2 className="text-lg font-bold text-on-surface">{title}</h2>
      {action}
    </div>
  );
}

export function Pill({
  label,
  onClick,
  color = 'bg-cyan-soft',
  textColor = 'text-cyan-deep',
  icon,
}: {
  label: string;
  onClick?: () => void;
  color?: string;
  textColor?: string;
  icon?: ReactNode;
}) {
  const Comp = onClick ? 'button' : 'span';
  return (
    <Comp
      type={onClick ? 'button' : undefined}
      onClick={onClick}
      className={`inline-flex items-center gap-1 rounded-pill px-3.5 py-2 text-[13px] font-bold ${color} ${textColor} ${onClick ? 'cursor-pointer transition hover:brightness-95' : ''}`}
    >
      {icon}
      {label}
    </Comp>
  );
}

export function ProgressRing({
  progress,
  size = 96,
  strokeWidth = 10,
  color = '#0aa8b8',
  trackColor = '#dde2e9',
  children,
}: {
  progress: number;
  size?: number;
  strokeWidth?: number;
  color?: string;
  trackColor?: string;
  children?: ReactNode;
}) {
  const clamped = Math.min(1, Math.max(0, progress));
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={radius} stroke={trackColor} strokeWidth={strokeWidth} fill="none" />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={color}
          strokeWidth={strokeWidth}
          fill="none"
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={circumference * (1 - clamped)}
          style={{ transition: 'stroke-dashoffset 300ms ease' }}
        />
      </svg>
      {children && <div className="absolute inset-0 flex items-center justify-center">{children}</div>}
    </div>
  );
}

interface GradientButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  label: string;
  gradient?: string;
  icon?: ReactNode;
}

export function GradientButton({
  label,
  gradient = 'from-cyan to-cyan-deep',
  icon,
  className = '',
  disabled,
  ...rest
}: GradientButtonProps) {
  return (
    <button
      type="button"
      disabled={disabled}
      className={`flex w-full items-center justify-center gap-2 rounded-pill py-3.5 text-[15px] font-extrabold text-white transition ${
        disabled ? 'bg-outline text-on-surface-variant' : `bg-gradient-to-br ${gradient} hover:brightness-105`
      } ${className}`}
      {...rest}
    >
      {icon}
      {label}
    </button>
  );
}

export function OutlineButton({
  label,
  icon,
  className = '',
  ...rest
}: ButtonHTMLAttributes<HTMLButtonElement> & { label: string; icon?: ReactNode }) {
  return (
    <button
      type="button"
      className={`flex w-full items-center justify-center gap-2 rounded-pill border-[1.4px] border-on-surface py-3 text-sm font-bold text-on-surface transition hover:bg-black/[0.03] ${className}`}
      {...rest}
    >
      {icon}
      {label}
    </button>
  );
}

export function GoogleSignInButton({
  label = 'Continue with Google',
  ...rest
}: ButtonHTMLAttributes<HTMLButtonElement> & { label?: string }) {
  return (
    <button
      type="button"
      className="flex w-full items-center justify-center gap-2.5 rounded-pill border border-outline bg-white py-3 text-sm font-bold text-on-surface transition hover:bg-black/[0.02]"
      {...rest}
    >
      <svg width="18" height="18" viewBox="0 0 18 18">
        <path fill="#4285F4" d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.72v2.26h2.9c1.7-1.57 2.7-3.88 2.7-6.62z" />
        <path fill="#34A853" d="M9 18c2.43 0 4.47-.8 5.96-2.18l-2.9-2.26c-.8.54-1.84.86-3.06.86-2.35 0-4.34-1.59-5.05-3.72H.96v2.33A9 9 0 0 0 9 18z" />
        <path fill="#FBBC05" d="M3.95 10.7A5.4 5.4 0 0 1 3.67 9c0-.59.1-1.17.28-1.7V4.97H.96A9 9 0 0 0 0 9c0 1.45.35 2.83.96 4.03z" />
        <path fill="#EA4335" d="M9 3.58c1.32 0 2.51.46 3.44 1.35l2.58-2.58C13.46.89 11.43 0 9 0A9 9 0 0 0 .96 4.97l2.99 2.33C4.66 5.17 6.65 3.58 9 3.58z" />
      </svg>
      {label}
    </button>
  );
}

export function OrDivider() {
  return (
    <div className="flex items-center gap-3">
      <div className="h-px flex-1 bg-outline" />
      <span className="text-xs text-on-surface-variant">or</span>
      <div className="h-px flex-1 bg-outline" />
    </div>
  );
}

export function TextField({
  label,
  className = '',
  ...rest
}: React.InputHTMLAttributes<HTMLInputElement> & { label: string }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-xs font-semibold text-on-surface-variant">{label}</span>
      <input
        className={`w-full rounded-md border border-outline bg-white px-3.5 py-2.5 text-sm text-on-surface outline-none transition focus:border-cyan ${className}`}
        {...rest}
      />
    </label>
  );
}

export function Switch({ checked, onChange }: { checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      className={`relative h-6 w-11 shrink-0 rounded-pill transition ${checked ? 'bg-cyan' : 'bg-outline'}`}
    >
      <span
        className={`absolute left-0.5 top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform ${
          checked ? 'translate-x-5' : 'translate-x-0'
        }`}
      />
    </button>
  );
}
