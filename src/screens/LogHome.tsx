import { FoodIcon, IChevronRight } from '../components/icons';
import { TopBar } from '../components/ui';
import { go } from '../lib/router';
import { online, settings } from '../lib/store';

export function LogHome() {
  const aiReady = online.value && !settings.value.simulateAiDown;
  return (
    <div class="screen ambient">
      <TopBar title="Log a meal" subtitle="Pick whichever is easiest right now" />
      <div class="stack">
        <button class="method" onClick={() => go('log/quick')}>
          <span class="m-ico"><FoodIcon name="moimoi" /></span>
          <span class="grow">
            <strong>Quick pick</strong>
            <span class="m-sub">Tap foods from a Nigerian food list</span>
          </span>
          <span class="badge leaf">Works offline</span>
        </button>
        <button class="method" onClick={() => go('log/portion')}>
          <span class="m-ico"><FoodIcon name="pack-md" /></span>
          <span class="grow">
            <strong>Portion mode</strong>
            <span class="m-sub">Pick the pack, plate or bowl, then how much you ate</span>
          </span>
          <span class="badge leaf">Works offline</span>
        </button>
        <button class="method" onClick={() => go('log/describe')}>
          <span class="m-ico"><FoodIcon name="ricebeans" /></span>
          <span class="grow">
            <strong>Describe it</strong>
            <span class="m-sub">Type it your way: "₦1,000 rice and beans, medium pack"</span>
          </span>
          {aiReady ? <IChevronRight class="chev" /> : <span class="badge ochre">Needs internet</span>}
        </button>
        <button class="method soon" onClick={() => go('log/photo')}>
          <span class="m-ico"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 8.5A1.5 1.5 0 0 1 5.5 7h2l1.5-2.5h6L16.5 7h2A1.5 1.5 0 0 1 20 8.5v9a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 17.5Z" /><circle cx="12" cy="13" r="3.5" /></svg></span>
          <span class="grow">
            <strong>Photo mode</strong>
            <span class="m-sub">Snap your plate and confirm what we see. Never required.</span>
          </span>
          <span class="badge">Coming soon</span>
        </button>
      </div>
      <p class="small faint" style={{ marginTop: '20px', textAlign: 'center' }}>No scale and no grams. You'll always check the result before anything is counted.</p>
    </div>
  );
}
