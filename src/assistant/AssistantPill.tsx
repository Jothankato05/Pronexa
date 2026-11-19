import { useEffect, useRef, useState } from 'preact/hooks';
import { settings } from '../lib/store';

/**
 * Pronexa's AI entry point, built on the HorizonX "Assistant Pill":
 * a glass prompt bar with a plasma orb, rotating example prompts and
 * status steps that sweep across the field while the meal is being read.
 *
 * The WebGL orb is loaded on demand. In low-data mode, with reduced motion,
 * or without WebGL 2, the pill keeps its CSS orb, so nothing breaks on low-end phones.
 */

export type PillState = 'idle' | 'thinking' | 'error';

// Per-state look of the orb (from the original prototype).
const LOOK: Record<PillState, { energy: number; warm: number; swirl: number }> = {
  idle: { energy: 0.38, warm: 0, swirl: 0 },
  thinking: { energy: 0.72, warm: 0, swirl: 1 },
  error: { energy: 0.2, warm: 1, swirl: 0 },
};

const hexToRgb = (hex: string) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255);
const COLORS = {
  Deep: hexToRgb('#1a4fe6'), Body: hexToRgb('#4fa8ff'), Glow: hexToRgb('#92dcff'),
  Plasma: hexToRgb('#6fd0ff'), Accent: hexToRgb('#ff8fc8'), Bg: hexToRgb('#18181a'),
};
// Small-orb tuning from the original (orb under ~58 px): thicker, faster strands and gentle surges.
const SMALL = { webScale: 0.5, strand: 1.5, core: 0.32, pace: 2.4, surge: 0.4 };
const surgeAt = (t: number, k: number) => k * (Math.pow(0.5 + 0.5 * Math.sin(t * 0.9), 4) + 0.5 * Math.pow(0.5 + 0.5 * Math.sin(t * 2.3 + 1.7), 6));

interface Props {
  value: string;
  onInput: (v: string) => void;
  onSubmit: (v: string) => void;
  state?: PillState;
  phrases?: string[];
  placeholder?: string;
  steps?: string[];
  errorText?: string;
  compact?: boolean;
  autoFocus?: boolean;
  label?: string;
  disabled?: boolean;
}

export function AssistantPill({
  value, onInput, onSubmit, state = 'idle', phrases = [], placeholder = 'Describe your meal…', steps = [], errorText,
  compact, autoFocus, label = 'Describe your meal', disabled,
}: Props) {
  const orbRef = useRef<HTMLButtonElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const spillRef = useRef<HTMLDivElement>(null);
  const live = useRef({ state, pulse: 0 });
  live.current.state = state;
  const [hasGl, setHasGl] = useState(false);

  // ── Rotating example prompts (blur in, shine, blur out) ──
  const rotation = [placeholder, ...phrases].filter(Boolean);
  const [idle, setIdle] = useState<{ cur: number; out: number | null }>({ cur: 0, out: null });
  const showIdle = !value && state === 'idle' && rotation.length > 1;
  useEffect(() => {
    if (!showIdle || matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    const id = setInterval(() => {
      setIdle((s) => ({ cur: (s.cur + 1) % rotation.length, out: s.cur }));
      setTimeout(() => setIdle((s) => ({ ...s, out: null })), 720);
    }, 2600);
    return () => clearInterval(id);
  }, [showIdle, rotation.length]);

  // ── Status steps while thinking ──
  const [step, setStep] = useState(0);
  useEffect(() => {
    if (state !== 'thinking' || steps.length < 2) { setStep(0); return; }
    const id = setInterval(() => setStep((i) => Math.min(steps.length - 1, i + 1)), 650);
    return () => clearInterval(id);
  }, [state, steps.join('|')]);

  // ── The plasma orb (WebGL 2), loaded only when it can run comfortably ──
  useEffect(() => {
    const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (settings.value.lowData || reduced || !canvasRef.current) return;
    let disposed = false;
    let renderer: { draw: (s: Record<string, unknown>) => boolean; dispose: () => void } | null = null;
    let raf = 0, last = 0, visible = true;
    const cur = { energy: 0.38, warm: 0, swirl: 0, level: 0, time: 5.7, spin: 0 };

    const frame = (now: number) => {
      raf = 0;
      if (disposed || !renderer) return;
      const dt = last ? Math.min(0.05, (now - last) / 1000) : 1 / 60;
      last = now;
      const want = LOOK[live.current.state];
      live.current.pulse *= Math.exp(-dt * 5);
      const target = live.current.pulse;
      cur.level += (target - cur.level) * (1 - Math.exp(-dt * (target > cur.level ? 16 : 5)));
      const e = 1 - Math.exp(-dt * 3.5);
      cur.energy += (want.energy - cur.energy) * e;
      cur.warm += (want.warm - cur.warm) * e;
      cur.swirl += (want.swirl - cur.swirl) * e;
      cur.time += dt * (0.55 + cur.energy * 1.1 + cur.level * 1.5);
      cur.spin += dt * (0.04 + cur.swirl * 0.9);
      const t = cur.time * SMALL.pace, surge = surgeAt(t, SMALL.surge);
      if (visible) {
        renderer.draw({
          time: t, dt, level: cur.level + surge * 0.4, energy: cur.energy + surge, warm: cur.warm, swirl: cur.swirl, spin: cur.spin,
          colors: COLORS, sphere: 0.5, steps: 24, maxSide: 320, bloom: 0.6, webScale: SMALL.webScale, strand: SMALL.strand, core: SMALL.core,
        });
      }
      if (spillRef.current) spillRef.current.style.opacity = (0.2 + cur.energy * 0.5 + cur.level * 0.8).toFixed(3);
      if (visible && !document.hidden) raf = requestAnimationFrame(frame);
    };
    const wake = () => { if (!disposed && !raf && renderer) { last = 0; raf = requestAnimationFrame(frame); } };
    const seen = typeof IntersectionObserver === 'function' ? new IntersectionObserver((en) => { visible = en.some((x) => x.isIntersecting); wake(); }) : null;

    import('./plasmaOrb.js').then((m) => {
      if (disposed || !canvasRef.current) return;
      try { renderer = m.createRenderer(canvasRef.current); } catch { renderer = null; }
      if (!renderer) return;
      setHasGl(true);
      if (orbRef.current) seen?.observe(orbRef.current);
      document.addEventListener('visibilitychange', wake);
      wake();
    }).catch(() => { /* stays on the CSS orb */ });

    return () => {
      disposed = true;
      if (raf) cancelAnimationFrame(raf);
      seen?.disconnect();
      document.removeEventListener('visibilitychange', wake);
      renderer?.dispose();
    };
  }, []);

  useEffect(() => { if (autoFocus) inputRef.current?.focus(); }, []);

  const busy = state === 'thinking';
  const submit = (e: Event) => {
    e.preventDefault();
    if (!value.trim() || busy || disabled) return;
    live.current.pulse = 1;
    onSubmit(value);
  };

  return (
    <form
      class={`apl${compact ? ' compact' : ''}`} data-state={state} data-busy={busy ? '' : undefined} data-idle={showIdle ? '' : undefined}
      onSubmit={submit} autocomplete="off" role="search" aria-label={label}
    >
      <div class="apl-spill" ref={spillRef} aria-hidden="true" />
      <button type="button" ref={orbRef} class={`apl-orb${hasGl ? ' apl-has-gl' : ''}`} aria-label="Focus the meal box" onClick={() => { live.current.pulse = 1; inputRef.current?.focus(); }}>
        <canvas ref={canvasRef} aria-hidden="true" />
      </button>
      <div class="apl-field">
        <input
          ref={inputRef} type="text" enterKeyHint="send" aria-label={label} value={value} disabled={disabled}
          placeholder={rotation[0]} maxLength={280}
          onInput={(e) => { live.current.pulse = Math.max(live.current.pulse, 0.22); onInput((e.target as HTMLInputElement).value); }}
        />
        <div class="apl-idle" aria-hidden="true">
          {idle.out !== null && <span key={`o${idle.out}`} class="apl-idle-line apl-out">{rotation[idle.out]}</span>}
          <span key={`c${idle.cur}`} class="apl-idle-line">{rotation[idle.cur]}</span>
        </div>
        <div class="apl-status" hidden={!(busy || state === 'error')} aria-live="polite">
          <span class="apl-step" key={`${state}${step}`}>{state === 'error' ? errorText : steps[step] ?? 'Reading your meal'}</span>
        </div>
      </div>
      <button class="apl-send" type="submit" aria-label="Read my meal" disabled={!value.trim() || busy || disabled}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 19V5.5" /><path d="M6 11.5l6-6 6 6" /></svg>
      </button>
    </form>
  );
}
