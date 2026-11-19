import { useMemo } from 'preact/hooks';
import { FoodIcon, ILeaf, IPlus } from '../components/icons';
import { Footnote, Switch, TopBar } from '../components/ui';
import { FOOD_BY_ID, PRICES_AS_OF_LABEL } from '../data/foods';
import { fmtNaira, fmtNairaRange, fmtRange, portionLabel } from '../lib/calc';
import { dietLabel } from '../lib/diet';
import { newKey } from '../lib/keys';
import { go } from '../lib/router';
import { solve, type Suggestion } from '../lib/solver';
import { draft, gap, profile, settings, target, todayMeals, updateSettings } from '../lib/store';

const BUDGETS = [300, 500, 1000, 2000];

function logSuggestion(items: Suggestion['item'][]) {
  draft.value = { source: 'quick', items: items.map((i) => ({ ...i, key: newKey(), portionSource: 'stated' })) };
  go('log/confirm');
}

export function Suggestions() {
  const p = profile.value!;
  const s = settings.value;
  const vegan = p.diet === 'vegan';
  const plantFirst = vegan || s.plantFirst;
  const hasMeals = todayMeals.value.length > 0;
  const g = hasMeals ? gap.value : target.value;

  const result = useMemo(
    () => solve({ gap: g, budget: s.budget, diet: p.diet, allergies: p.allergies, plantFirst, meals: todayMeals.value }),
    [g.mid, s.budget, p.diet, p.allergies.join(), plantFirst, todayMeals.value],
  );
  const closed = hasMeals && g.mid <= 0;

  return (
    <div class="screen">
      <TopBar title="Close the gap" subtitle="Affordable protein that fits how you eat" />

      <section class="card hero gap-card" aria-label="Your protein gap">
        <div class="orb-tile" aria-hidden="true"><ILeaf /></div>
        <div class="dots" aria-hidden="true"><i class="on" /><i /><i /></div>
        {closed ? (
          <>
            <p class="big" style={{ marginTop: '20px', fontSize: '34px' }}>Gap closed</p>
            <p class="label">Ideas to keep handy for tomorrow</p>
          </>
        ) : (
          <>
            <p class="big num" style={{ marginTop: '20px' }}>{fmtRange(g).replace(' g', '')}<small> g</small></p>
            <p class="label">{hasMeals ? 'Left to eat today' : "Today's full target"}</p>
          </>
        )}
      </section>

      <section class="section" aria-label="Budget and preferences">
        <span class="field-label">My budget</span>
        <div class="budget-row" role="radiogroup" aria-label="Budget">
          {BUDGETS.map((b) => (
            <button class="chip" role="radio" aria-checked={s.budget === b} aria-pressed={s.budget === b} onClick={() => updateSettings({ budget: b })}>{fmtNaira(b)}</button>
          ))}
        </div>
        <div class="group" style={{ marginTop: '16px' }}>
          <div class="setting-row">
            <ILeaf class="s-ico" />
            <label class="grow" for="plant-first">
              <strong>Plant-first</strong>
              <span>{vegan ? 'Always on: you eat vegan, so we only show plants.' : 'Beans, soy and groundnuts come first.'}</span>
            </label>
            {vegan ? <span class="tag good">On</span> : <Switch id="plant-first" label="Plant-first" checked={plantFirst} onChange={(v) => updateSettings({ plantFirst: v })} />}
          </div>
        </div>
        <p class="caption faint" style={{ marginTop: '10px', paddingLeft: '8px' }}>
          For: {dietLabel(p.diet)}{p.allergies.length ? `, no ${p.allergies.join(', ')}` : ''}. <a href="#/settings">Change</a>
        </p>
      </section>

      <div class="paper-sheet paper">
        {!closed && result.combos.length > 0 && (
          <section>
            <h2 style={{ marginBottom: '16px' }}>Ways to close it</h2>
            {result.combos.map((c) => (
              <article class="combo">
                <div class="row-between" style={{ alignItems: 'flex-start' }}>
                  <div class="grow">
                    <h3>{c.title}</h3>
                    <p class="small faint">{c.subtitle}</p>
                  </div>
                  <span class={`tag ${c.closesGap ? 'good' : 'gap'}`}>{c.closesGap ? 'Closes it' : `${Math.round((c.protein.mid / Math.max(1, g.mid)) * 100)}%`}</span>
                </div>
                <div class="combo-items">
                  {c.items.map((it) => (
                    <div class="combo-item">
                      <span class="ci-ico"><FoodIcon name={FOOD_BY_ID[it.foodId].icon} /></span>
                      <span class="grow"><strong>{FOOD_BY_ID[it.foodId].name}</strong><span class="caption faint" style={{ display: 'block' }}>{portionLabel(it.item)}</span></span>
                      <span class="small num" style={{ fontWeight: 500, color: 'var(--good)' }}>+{fmtRange(it.protein)}</span>
                    </div>
                  ))}
                </div>
                <div class="combo-foot">
                  <div class="row-between">
                    <span class="small faint">Total</span>
                    <span class="num"><strong>about {fmtRange(c.protein)}</strong> <span class="faint">for ~{fmtNaira(c.cost)}</span></span>
                  </div>
                  <button class="btn btn-secondary btn-small btn-block" onClick={() => logSuggestion(c.items.map((i) => i.item))}><IPlus /> I ate this</button>
                </div>
              </article>
            ))}
          </section>
        )}

        {result.upgrades.length > 0 && (
          <section class="section">
            <h2>{hasMeals ? "Upgrade today's meals" : 'Easy upgrades to everyday meals'}</h2>
            <p class="small faint" style={{ margin: '-10px 0 4px' }}>Keep the meal you like. Just add a little more protein.</p>
            {result.upgrades.map((u) => {
              const f = FOOD_BY_ID[u.suggestion.foodId];
              return (
                <article class="upgrade">
                  <div class="flow">
                    <span>{u.title}</span>
                    <span class="arrow" aria-hidden="true">→</span>
                    <span class="add">{u.kind === 'swap' ? `swap ${FOOD_BY_ID[u.fromFoodId!].name.toLowerCase()} for ${f.name.toLowerCase()}` : `+ ${portionLabel(u.suggestion.item)} ${f.name.toLowerCase()}`}</span>
                  </div>
                  <div class="metrics">
                    <span class="metric leaf">+{fmtRange(u.proteinChange)}</span>
                    <span class="metric">{u.costChange >= 0 ? '+' : '−'}{fmtNaira(Math.abs(u.costChange))}</span>
                    <span class="metric value">{u.suggestion.per100.toFixed(1)} g per ₦100</span>
                  </div>
                  <p class="small muted">{u.reason}</p>
                  {u.suggestion.caveat && <p class="caption" style={{ color: 'var(--gap)' }}>{u.suggestion.caveat}</p>}
                </article>
              );
            })}
          </section>
        )}

        <section class="section">
          <h2>Best protein for your money</h2>
          {result.ranked.length === 0 ? (
            <div class="empty">
              <h3>Nothing fits that budget yet</h3>
              <p>Try a slightly bigger budget. Even ₦300 can buy a handful of groundnuts or soya chunks.</p>
            </div>
          ) : (
            result.ranked.slice(0, 8).map((sug) => <SuggestionCard s={sug} />)
          )}
          {result.excludedCount > 0 && (
            <p class="caption faint" style={{ marginTop: '12px' }}>{result.excludedCount} foods are hidden because they don't fit your diet or allergies.</p>
          )}
        </section>

        <p class="caption faint" style={{ marginTop: '24px' }}>
          Ranked by protein per naira, how much of your gap it closes, and your diet. Prices are typical campus prices from {PRICES_AS_OF_LABEL} and vary by vendor. Protein amounts are estimates.
        </p>
        <Footnote />
      </div>
    </div>
  );
}

function SuggestionCard({ s }: { s: Suggestion }) {
  const f = FOOD_BY_ID[s.foodId];
  return (
    <article class="sug">
      <span class="fi-wrap"><FoodIcon name={f.icon} /></span>
      <div class="sug-body">
        <div class="sug-title">
          <strong>{f.name}</strong>
          <span class="plus num">+{fmtRange(s.protein)}</span>
        </div>
        <span class="caption faint">{portionLabel(s.item)}{s.plant && f.altProtein ? ' · plant protein' : ''}</span>
        <div class="metrics">
          <span class="metric">{fmtNairaRange(s.price)}</span>
          <span class="metric value">{s.per100.toFixed(1)} g per ₦100</span>
          {s.gapShare > 0 && <span class="metric leaf">{Math.round(s.gapShare * 100)}% of gap</span>}
        </div>
        <p class="reason">{s.reason}</p>
        {s.caveat && <p class="caveat">{s.caveat}</p>}
        <button class="link-btn accent" style={{ marginLeft: '-8px' }} onClick={() => logSuggestion([s.item])}><IPlus /> I ate this</button>
      </div>
    </article>
  );
}
