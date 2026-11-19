import { useState } from 'preact/hooks';
import { ICheck, IChevronLeft, ICloudOff, IInfo, ILeaf, PronexaMark } from '../components/icons';
import type { Activity, Allergen, Diet } from '../data/types';
import { ACTIVITY, DEFAULT_WEIGHT_KG, fmtRange, proteinTarget } from '../lib/calc';
import { ALLERGENS, DIETS } from '../lib/diet';
import { go } from '../lib/router';
import { saveProfile, updateSettings } from '../lib/store';

const STEPS = 6;

export function Onboarding() {
  const [step, setStep] = useState(0);
  const [consentSync, setConsentSync] = useState(false);
  const [diet, setDiet] = useState<Diet | null>(null);
  const [allergies, setAllergies] = useState<Allergen[] | null>(null);
  const [weight, setWeight] = useState<number>(DEFAULT_WEIGHT_KG);
  const [weightKnown, setWeightKnown] = useState(true);
  const [activity, setActivity] = useState<Activity | null>(null);

  const next = () => setStep((s) => Math.min(STEPS - 1, s + 1));
  const prev = () => setStep((s) => Math.max(0, s - 1));
  const target = proteinTarget({ weightKg: weightKnown ? weight : null, activity: activity ?? 'moderate' });
  const setKg = (v: number) => { setWeight(Math.max(30, Math.min(200, v))); setWeightKnown(true); };

  const finish = () => {
    saveProfile({ diet: diet ?? 'none', allergies: allergies ?? [], weightKg: weightKnown ? weight : null, activity: activity ?? 'moderate', createdAt: Date.now() });
    updateSettings({ syncEnabled: consentSync, plantFirst: true });
    go('today', undefined, { replace: true });
  };

  const toggleAllergy = (a: Allergen) => {
    const cur = allergies ?? [];
    setAllergies(cur.includes(a) ? cur.filter((x) => x !== a) : [...cur, a]);
  };

  // ── Splash ──
  if (step === 0) {
    return (
      <div class="splash screen">
        <div class="mark"><PronexaMark size={150} /></div>
        <h1>Making every<br />meal count</h1>
        <p class="lead">See if the food you already eat gives you enough protein, and find cheap ways to close the gap.</p>
        <div class="stack" style={{ marginTop: '28px', gap: '14px' }}>
          <div class="promise"><span class="p-ico"><ILeaf /></span><p class="small" style={{ color: 'rgb(255 255 255 / .74)' }}>No scale, no grams. Naira, packs, wraps and spoons.</p></div>
          <div class="promise"><span class="p-ico"><ICloudOff /></span><p class="small" style={{ color: 'rgb(255 255 255 / .74)' }}>Works offline. Your log lives on this phone.</p></div>
          <div class="promise"><span class="p-ico"><IInfo /></span><p class="small" style={{ color: 'rgb(255 255 255 / .74)' }}>Honest estimates. Not medical advice.</p></div>
        </div>
        <div class="stack" style={{ marginTop: '32px', gap: '8px' }}>
          <button class="btn btn-primary btn-block" onClick={next}>Get started</button>
          <p class="caption" style={{ textAlign: 'center', color: 'rgb(255 255 255 / .66)', padding: '12px 0' }}>No name, email or phone number needed.</p>
        </div>
      </div>
    );
  }

  return (
    <div class="app no-tabs">
      <div class="onb">
        <div class="onb-top">
          <button class="icon-btn plain" onClick={prev} aria-label="Back"><IChevronLeft /></button>
          <div class="steps grow" aria-label={`Step ${step} of ${STEPS - 1}`} style={{ margin: 0 }}>
            {Array.from({ length: STEPS - 1 }, (_, i) => <i class={i < step ? 'on' : ''} />)}
          </div>
        </div>

        <div class="onb-body screen" key={step}>
          {step === 1 && (
            <>
              <h1>How do you eat?</h1>
              <p class="lead">We only ever suggest foods that fit. You can change this later.</p>
              <span class="field-label">Dietary preference</span>
              <div class="choice-list" role="radiogroup" aria-label="Dietary preference">
                {DIETS.map((d) => (
                  <button class="choice" role="radio" aria-checked={diet === d.id} onClick={() => setDiet(d.id)}>
                    <span class="grow"><strong>{d.label}</strong><span class="sub">{d.detail}</span></span>
                    <span class="tick"><ICheck /></span>
                  </button>
                ))}
              </div>
            </>
          )}

          {step === 2 && (
            <>
              <h1>Any food allergies?</h1>
              <p class="lead">Asked separately, because being vegan doesn't mean you're allergic. Tap all that apply.</p>
              <div class="chips" role="group" aria-label="Allergies">
                <button class="chip" aria-pressed={allergies !== null && allergies.length === 0} onClick={() => setAllergies([])}>No allergies</button>
                {ALLERGENS.map((a) => (
                  <button class="chip" aria-pressed={!!allergies?.includes(a.id)} onClick={() => toggleAllergy(a.id)}>
                    {allergies?.includes(a.id) && <ICheck />}
                    {a.label}
                  </button>
                ))}
              </div>
              <p class="small faint" style={{ marginTop: '20px' }}>Pronexa hides foods with these allergens, including soups that may contain crayfish.</p>
            </>
          )}

          {step === 3 && (
            <>
              <h1>About how much do you weigh?</h1>
              <p class="lead">Protein needs grow with body weight. A rough number is fine.</p>
              <div class="card" style={{ textAlign: 'center', opacity: weightKnown ? 1 : 0.5, transition: 'opacity .2s' }}>
                <div class="weight-display">
                  <button class="wbtn" onClick={() => setKg(weight - 1)} aria-label="Less">−</button>
                  <div>
                    <label class="sr-only" for="kg">Weight in kilograms</label>
                    <input id="kg" class="num" type="number" inputMode="numeric" min={30} max={200} value={weight}
                      onInput={(e) => { const v = parseInt((e.target as HTMLInputElement).value, 10); if (v >= 30 && v <= 200) setKg(v); }} />
                    <span>kg</span>
                  </div>
                  <button class="wbtn" onClick={() => setKg(weight + 1)} aria-label="More">+</button>
                </div>
                <div class="chips" style={{ justifyContent: 'center' }}>
                  {[45, 55, 65, 75, 85].map((kg) => (
                    <button class="chip small" aria-pressed={weightKnown && weight === kg} onClick={() => setKg(kg)}>{kg}</button>
                  ))}
                </div>
              </div>
              <button class="consent" style={{ marginTop: '16px' }} role="checkbox" aria-checked={!weightKnown} onClick={() => { setWeightKnown(!weightKnown); setWeight(DEFAULT_WEIGHT_KG); }}>
                <span class="box"><ICheck /></span>
                Not sure, use an average ({DEFAULT_WEIGHT_KG} kg)
              </button>
            </>
          )}

          {step === 4 && (
            <>
              <h1>How active is a normal week?</h1>
              <p class="lead">Active bodies repair more, so they need a bit more protein.</p>
              <div class="choice-list" role="radiogroup" aria-label="Activity level">
                {(Object.keys(ACTIVITY) as Activity[]).map((a) => (
                  <button class="choice" role="radio" aria-checked={activity === a} onClick={() => setActivity(a)}>
                    <span class="grow"><strong>{ACTIVITY[a].label}</strong><span class="sub">{ACTIVITY[a].detail}</span></span>
                    <span class="tick"><ICheck /></span>
                  </button>
                ))}
              </div>
            </>
          )}

          {step === 5 && (
            <>
              <div class="card hero target-reveal">
                <p class="eyebrow" style={{ color: 'rgb(255 255 255 / .74)' }}>Your daily protein estimate</p>
                <p class="big num">{Math.round(target.mid)}<small> g</small></p>
                <p style={{ color: 'rgb(255 255 255 / .74)' }}>a day, roughly {fmtRange(target)}</p>
              </div>
              <div class="stack" style={{ marginTop: '24px' }}>
                <p class="small muted">
                  Worked out as {ACTIVITY[activity ?? 'moderate'].gPerKg.join('–')} g of protein per kg × {weightKnown ? `${weight} kg` : `an average ${DEFAULT_WEIGHT_KG} kg`}.
                </p>
                <p class="small muted">Needs differ with age, pregnancy, illness and more. If any of that applies to you, a health professional can give you a better number.</p>
                <button class="consent" role="checkbox" aria-checked={consentSync} onClick={() => setConsentSync(!consentSync)} style={{ marginTop: '8px' }}>
                  <span class="box"><ICheck /></span>
                  Back up my meal log when I'm online (optional, no name or email)
                </button>
              </div>
            </>
          )}
        </div>

        <div class="sticky-cta">
          {step === 1 && <button class="btn btn-primary btn-block" disabled={!diet} onClick={next}>Continue</button>}
          {step === 2 && <button class="btn btn-primary btn-block" disabled={allergies === null} onClick={next}>Continue</button>}
          {step === 3 && <button class="btn btn-primary btn-block" onClick={next}>Continue</button>}
          {step === 4 && <button class="btn btn-primary btn-block" disabled={!activity} onClick={next}>See my estimate</button>}
          {step === 5 && <button class="btn btn-primary btn-block" onClick={finish}>Go to Today</button>}
        </div>
      </div>
    </div>
  );
}
