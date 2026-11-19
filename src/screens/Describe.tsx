import { useEffect, useRef, useState } from 'preact/hooks';
import { interpretMeal, setInterpretCache } from '../ai';
import type { RawInterpretation } from '../ai/types';
import { AssistantPill, type PillState } from '../assistant/AssistantPill';
import { ICloudOff } from '../components/icons';
import { TopBar } from '../components/ui';
import * as db from '../lib/db';
import { back, current, go } from '../lib/router';
import { draft, online, settings } from '../lib/store';

// Repeat descriptions are answered from the phone, even offline.
setInterpretCache({
  get: (k) => db.get<RawInterpretation>('aicache', k),
  set: (k, v) => db.set('aicache', k, v),
});

const EXAMPLES = [
  '₦1,000 rice and beans, medium takeaway',
  'I chop 2 wraps of eba with egusi and one meat',
  'Bread and 4 akara, ₦600',
  'Soaked garri with groundnut',
  'Jollof rice big pack with chicken',
];
const STEPS = ['Reading your words', 'Matching Nigerian foods', 'Checking the portion'];

type Fail = 'offline' | 'unavailable' | 'nothing-found' | null;

export function Describe() {
  const param = current.value.param ?? '';
  const initial = param.startsWith('q=') ? decodeURIComponent(param.slice(2)) : '';
  const [text, setText] = useState(initial);
  const [state, setState] = useState<PillState>('idle');
  const [fail, setFail] = useState<Fail>(null);
  const [unknown, setUnknown] = useState<string[]>([]);
  const ctrl = useRef<AbortController | null>(null);
  const isOnline = online.value;
  const aiDown = settings.value.simulateAiDown;

  useEffect(() => () => ctrl.current?.abort(), []);

  const run = async (value: string) => {
    setFail(null);
    setState('thinking');
    ctrl.current = new AbortController();
    const started = Date.now();
    const res = await interpretMeal(value, { online: online.value, simulateDown: settings.value.simulateAiDown, signal: ctrl.current.signal });
    // Let the status steps finish their sweep so the moment feels deliberate, not jumpy.
    const wait = Math.max(0, 1500 - (Date.now() - started));
    if (wait) await new Promise((r) => setTimeout(r, wait));
    if (!res.ok) {
      if (res.reason === 'empty') { setState('idle'); return; }
      setUnknown(res.unknown ?? []);
      setFail(res.reason);
      setState(res.reason === 'nothing-found' ? 'error' : 'idle');
      return;
    }
    setState('idle');
    const r = res.result;
    draft.value = { source: 'describe', text: value, price: r.price, items: r.items, confidence: r.confidence, question: r.question, notes: r.notes, unknown: r.unknown };
    go('log/confirm', undefined, { replace: !!initial });
  };

  useEffect(() => {
    if (initial && isOnline && !aiDown) void run(initial);
  }, []);

  const fallback = fail === 'offline' || fail === 'unavailable' || !isOnline || aiDown;

  return (
    <div class="screen ambient">
      <TopBar title="Describe it" subtitle="English or Pidgin, naira or pack size" backTo={() => back('log')} />

      {fallback ? (
        <div class="card stack" style={{ marginTop: '16px' }}>
          <div class="row" style={{ alignItems: 'flex-start' }}>
            <span style={{ width: '48px', height: '48px', borderRadius: '13px', background: 'var(--gap-tint)', color: 'var(--gap)', display: 'grid', placeItems: 'center', flex: 'none' }}><ICloudOff width={24} height={24} /></span>
            <div>
              <h3>{fail === 'unavailable' || aiDown ? 'Our meal reader is resting' : "You're offline right now"}</h3>
              <p class="small muted" style={{ marginTop: '4px' }}>
                No wahala. Describe it needs internet, but Quick pick and Portion mode work fully offline and count exactly the same way.
              </p>
            </div>
          </div>
          <button class="btn btn-primary btn-block" style={{ marginTop: '8px' }} onClick={() => go('log/quick', undefined, { replace: true })}>Use Quick pick instead</button>
          <button class="btn btn-secondary btn-block" onClick={() => go('log/portion', undefined, { replace: true })}>Use Portion mode</button>
          {fail && isOnline && !aiDown && <button class="btn btn-ghost" onClick={() => setFail(null)}>Try describing again</button>}
        </div>
      ) : (
        <>
          <p class="muted" style={{ margin: '24px 0 20px', textAlign: 'center' }}>Tell me what you ate, the way you'd tell a friend.</p>
          <AssistantPill
            value={text} onInput={(v) => { setText(v); if (fail) { setFail(null); setState('idle'); } }} onSubmit={run}
            state={state} phrases={EXAMPLES.slice(1)} placeholder={EXAMPLES[0]} steps={STEPS} autoFocus={!initial}
            errorText="Hmm, I didn't catch any foods"
          />

          {fail === 'nothing-found' && (
            <div class="card" style={{ marginTop: '20px' }}>
              <h3>I didn't catch any foods I know</h3>
              <p class="small muted" style={{ marginTop: '4px' }}>
                {unknown.length ? `I don't know "${unknown.slice(0, 2).join('", "')}" yet. ` : ''}Try simple words like "rice and beans" or "eba and egusi", or pick from the list.
              </p>
              <button class="btn btn-secondary btn-block" style={{ marginTop: '14px' }} onClick={() => go('log/quick')}>Pick from the list</button>
            </div>
          )}

          {state !== 'thinking' && !fail && (
            <div style={{ marginTop: '32px' }}>
              <p class="eyebrow" style={{ marginBottom: '12px' }}>Try one of these</p>
              <div class="chips">
                {EXAMPLES.map((ex) => <button class="chip small wrapy" onClick={() => { setText(ex); void run(ex); }}>{ex}</button>)}
              </div>
            </div>
          )}

          <p class="small faint" style={{ marginTop: '32px', textAlign: 'center' }}>
            The AI only picks foods from our checked list. You confirm everything, and the protein numbers come from the food database.
          </p>
        </>
      )}
    </div>
  );
}
