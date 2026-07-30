import type { ReactNode } from 'react';

export function AuthShell({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle: string;
  children: ReactNode;
}) {
  return (
    <div className="flex min-h-svh items-center justify-center bg-background px-6 py-12">
      <div className="w-full max-w-sm">
        <div className="mb-6 flex h-16 w-16 items-center justify-center rounded-xl bg-gradient-to-br from-cyan to-cyan-deep text-2xl text-white shadow-lg shadow-cyan/30">
          ⚡
        </div>
        <h1 className="text-2xl font-extrabold tracking-tight text-on-surface">{title}</h1>
        <p className="mt-1.5 text-sm text-on-surface-variant">{subtitle}</p>
        <div className="mt-8 flex flex-col gap-4">{children}</div>
      </div>
    </div>
  );
}
