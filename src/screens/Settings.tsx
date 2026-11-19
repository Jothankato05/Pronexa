import { useState } from 'preact/hooks';
import { IBolt, ICheck, ICloud, IDownload, IInfo, IPhone, IRefresh, IShield, ITrash, IUser } from '../components/icons';
import { Sheet, Stepper, Switch, TopBar } from '../components/ui';
import { DB_VERSION, FOODS, PRICES_AS_OF_LABEL } from '../data/foods';
import type { Activity, Allergen, Diet } from '../data/types';
import { ACTIVITY, DEFAULT_WEIGHT_KG, fmtRange } from '../lib/calc';
import { ALLERGENS, DIETS, dietLabel } from '../lib/diet';
import { back, go } from '../lib/router';
import {
  exportData, installPrompt, lastSyncedAt, loadDemoDay, online, profile, resetAll, saveProfile, settings, showToast,
  syncNow, syncState, target, unsyncedCount, updateSettings,
} from '../lib/store';

export function Settings() {
  const p = profile.value!;
  const s = settings.value;
  const [confirmDelete, setConfirmDelete] = useState(false);

  const setP = (patch: Partial<typeof p>) => saveProfile({ ...p, ...patch });
  const toggleAllergy = (a: Allergen) => setP({ allergies: p.allergies.includes(a) ? p.allergies.filter((x) => x !== a) : [...p.allergies, a] });

  const download = () => {
    const blob = new Blob([exportData()], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `pronexa-data-${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  };

  const syncLabel = !online.value ? 'Offline: will sync later' : syncState.value === 'syncing' ? 'Syncing…' : unsyncedCount.value ? `${unsyncedCount.value} meal${unsyncedCount.value > 1 ? 's' : ''} waiting` : 'All synced';

  return (
    <div class="screen">
      <TopBar title="Profile" subtitle="You & settings" backTo={() => back('today')} />

      <section class="profile" aria-label="Your profile">
        <div class="avatar"><IUser /></div>
        <div>
          <h2>Your profile</h2>
          <p class="tagline">{dietLabel(p.diet)} · ~{Math.round(target.value.mid)} g a day</p>
          <p class="caption faint" style={{ marginTop: '6px' }}>Estimate range {fmtRange(target.value)}</p>
        </div>
      </section>

      <section class="section" style={{ marginTop: '8px' }}>
        <p class="eyebrow group-title">How you eat</p>
        <div class="card stack">
          <div class="chips" role="radiogroup" aria-label="Dietary preference">
            {DIETS.map((d) => (
              <button class="chip small" role="radio" aria-checked={p.diet === d.id} aria-pressed={p.diet === d.id} onClick={() => setP({ diet: d.id as Diet })}>{d.label}</button>
            ))}
          </div>
          <span class="field-label" style={{ marginTop: '8px', padding: 0 }}>Allergies</span>
          <div class="chips" role="group" aria-label="Allergies">
            {ALLERGENS.map((a) => (
              <button class="chip small" aria-pressed={p.allergies.includes(a.id)} onClick={() => toggleAllergy(a.id)}>
                {p.allergies.includes(a.id) && <ICheck />}{a.label}
              </button>
            ))}
          </div>
        </div>
      </section>

      <section class="section">
        <p class="eyebrow group-title">Your estimate</p>
        <div class="card stack">
          <div class="row-between">
            <span><strong style={{ display: 'block' }}>Weight</strong><span class="small faint">{p.weightKg ? `${p.weightKg} kg` : `Not set (using ${DEFAULT_WEIGHT_KG} kg)`}</span></span>
            <Stepper value={p.weightKg ?? DEFAULT_WEIGHT_KG} min={30} max={200} onChange={(v) => setP({ weightKg: v })} />
          </div>
          <div class="chips" role="radiogroup" aria-label="Activity level">
            {(Object.keys(ACTIVITY) as Activity[]).map((a) => (
              <button class="chip small" role="radio" aria-checked={p.activity === a} aria-pressed={p.activity === a} onClick={() => setP({ activity: a })}>{ACTIVITY[a].label}</button>
            ))}
          </div>
          <p class="caption faint">{ACTIVITY[p.activity].gPerKg.join('–')} g per kg. Needs differ with age, pregnancy and illness; a health professional can advise.</p>
        </div>
      </section>

      <section class="section">
        <p class="eyebrow group-title">Preferences</p>
        <div class="group">
          <div class="setting-row">
            <IBolt class="s-ico" />
            <label class="grow" for="low-data"><strong>Low-data mode</strong><span>System font, a still orb, and sync only when you tap.</span></label>
            <Switch id="low-data" label="Low-data mode" checked={s.lowData} onChange={(v) => updateSettings({ lowData: v })} />
          </div>
          <div class="setting-row">
            <ICloud class="s-ico" />
            <label class="grow" for="sync"><strong>Back up when online</strong><span>No name or email. Off keeps your log on this phone only.</span></label>
            <Switch id="sync" label="Back up when online" checked={s.syncEnabled} onChange={(v) => updateSettings({ syncEnabled: v })} />
          </div>
          {s.syncEnabled && (
            <div class="setting-row">
              <IRefresh class="s-ico" />
              <span class="grow">
                <strong>{syncLabel}</strong>
                <span>{lastSyncedAt.value ? `Last synced ${new Date(lastSyncedAt.value).toLocaleString('en-NG', { hour: 'numeric', minute: '2-digit', day: 'numeric', month: 'short' })}` : 'Not synced yet'}</span>
              </span>
              <button class="btn btn-secondary btn-small" disabled={!online.value || syncState.value === 'syncing'} onClick={async () => { const ok = await syncNow(); showToast(ok ? 'All synced.' : "Couldn't sync. We'll try again later."); }}>Sync</button>
            </div>
          )}
          {installPrompt.value && (
            <div class="setting-row">
              <IPhone class="s-ico" />
              <span class="grow"><strong>Install the app</strong><span>Opens from your home screen, works offline.</span></span>
              <button class="btn btn-primary btn-small" onClick={async () => { await installPrompt.value!.prompt(); installPrompt.value = null; }}>Install</button>
            </div>
          )}
        </div>
      </section>

      <section class="section">
        <p class="eyebrow group-title">Privacy</p>
        <div class="group">
          <div class="setting-row">
            <IShield class="s-ico" />
            <span class="grow"><strong>Your data stays yours</strong><span>Profile and meals live on this phone. We never ask for your name, email or number, and never sell data.</span></span>
          </div>
          <button class="setting-row" style={{ width: '100%', background: 'none', border: 0, borderTop: '1px solid var(--line-soft)', color: 'inherit', textAlign: 'left' }} onClick={download}>
            <IDownload class="s-ico" />
            <span class="grow"><strong>Download my data</strong><span>A JSON file of everything Pronexa stores.</span></span>
          </button>
          <button class="setting-row" style={{ width: '100%', background: 'none', border: 0, borderTop: '1px solid var(--line-soft)', color: 'var(--danger)', textAlign: 'left' }} onClick={() => setConfirmDelete(true)}>
            <ITrash class="s-ico" style={{ color: 'var(--danger)' }} />
            <span class="grow"><strong>Delete everything</strong></span>
          </button>
        </div>
      </section>

      <section class="section">
        <p class="eyebrow group-title">About the numbers</p>
        <div class="card stack">
          <p class="small muted"><IInfo width={15} height={15} style={{ verticalAlign: '-2px', marginRight: '6px' }} />
            Protein values come from Pronexa's starter database ({FOODS.length} foods, v{DB_VERSION}), based on the West African Food Composition Table and USDA data, with typical campus portions. They're estimates, still to be checked by nutrition professionals and real vendor measurements.
          </p>
          <p class="small muted">Prices are typical campus prices from {PRICES_AS_OF_LABEL}, used only as a clue, never as a measure of how much you ate.</p>
        </div>
      </section>

      <section class="section">
        <p class="eyebrow group-title">Demo tools</p>
        <div class="group">
          <button class="setting-row" style={{ width: '100%', background: 'none', border: 0, color: 'inherit', textAlign: 'left' }} onClick={() => { loadDemoDay(); go('today'); }}>
            <IRefresh class="s-ico" />
            <span class="grow"><strong>Load a demo day</strong><span>Adds a sample breakfast and lunch.</span></span>
          </button>
          <div class="setting-row">
            <IInfo class="s-ico" />
            <label class="grow" for="ai-down"><strong>Pretend the AI is down</strong><span>Shows the friendly fallback to Quick pick.</span></label>
            <Switch id="ai-down" label="Pretend the AI is unavailable" checked={s.simulateAiDown} onChange={(v) => updateSettings({ simulateAiDown: v })} />
          </div>
        </div>
      </section>

      <Sheet open={confirmDelete} onClose={() => setConfirmDelete(false)} title="Delete everything?">
        <p class="muted" style={{ marginBottom: '20px' }}>This removes your profile, meals and settings from this phone. It can't be undone.</p>
        <div class="stack">
          <button class="btn btn-primary btn-block" style={{ background: 'var(--clay-700)', boxShadow: 'none' }} onClick={async () => { await resetAll(); setConfirmDelete(false); location.hash = ''; }}>Yes, delete my data</button>
          <button class="btn btn-secondary btn-block" onClick={() => setConfirmDelete(false)}>Keep my data</button>
        </div>
      </Sheet>
    </div>
  );
}
