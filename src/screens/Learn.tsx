import { FoodIcon, ICalendar, IChevronRight, ILeaf, IMap, ITrophy, IBook, ICamera } from '../components/icons';
import { Footnote, TopBar } from '../components/ui';
import { back, current, go } from '../lib/router';
import { fmtRange, itemsProtein } from '../lib/calc';

const SOON = {
  lessons: { title: 'Short protein lessons', sub: 'What protein does, plant vs animal sources, common myths. 2 minutes each, downloadable for offline.', Icon: IBook },
  challenge: { title: '₦500 Protein Challenge', sub: 'How much protein can ₦500 buy? Weekly combos and a friendly streak.', Icon: ITrophy },
  planner: { title: 'Plant-based Meal Planner', sub: 'Affordable daily plans for vegan and plant-based students.', Icon: ICalendar },
  map: { title: 'Campus Protein Map', sub: 'Find affordable protein: vendors, markets and buka spots near campus.', Icon: IMap },
  photo: { title: 'Photo mode', sub: 'Snap your plate and confirm the foods we think we see. Always optional, never required.', Icon: ICamera },
} as const;

export function Learn() {
  return (
    <div class="screen">
      <TopBar title="Learn" subtitle="Small lessons, big difference" />

      <article class="card hero">
        <p class="eyebrow">Did you know?</p>
        <h3 style={{ margin: '4px 0 6px' }}>Beans + rice is a team</h3>
        <p class="small muted">Beans and grains carry different protein building blocks. Eaten in the same day, they work together. That's why rice and beans, or bread and akara, are such good combos.</p>
      </article>

      <section class="section">
        <h2>For plant-based eaters</h2>
        <div class="card flat stack">
          <p class="small muted">If you eat fully plant-based, keep an eye on these. This is awareness, not medical advice.</p>
          {[
            ['Vitamin B12', 'Only reliable from fortified foods or supplements.'],
            ['Iron', 'Beans, lentils, ugu (pumpkin leaves). Pair with vitamin C, like oranges or tomatoes.'],
            ['Calcium', 'Tofu (awara), fortified soy milk, leafy greens.'],
            ['Zinc', 'Beans, groundnuts, seeds and whole grains.'],
            ['Omega-3', 'Small amounts in soybeans and some seeds.'],
          ].map(([t, d]) => (
            <div class="row" style={{ alignItems: 'flex-start' }}>
              <ILeaf width={20} height={20} style={{ color: 'var(--good)', flex: 'none', marginTop: '3px' }} />
              <div><strong>{t}</strong><p class="small muted">{d}</p></div>
            </div>
          ))}
        </div>
      </section>

      <section class="section">
        <h2>Coming soon</h2>
        {(['lessons', 'challenge', 'planner', 'map'] as const).map((k) => {
          const { title, sub, Icon } = SOON[k];
          return (
            <button class="soon-card" onClick={() => go('learn/soon', k)}>
              <span class="s-ico"><Icon /></span>
              <span class="grow"><strong>{title}</strong><span class="sub">{sub}</span></span>
              <IChevronRight width={22} height={22} style={{ color: 'var(--ink-3)', flex: 'none' }} />
            </button>
          );
        })}
      </section>
      <Footnote />
    </div>
  );
}

export function ComingSoon() {
  const key = (current.value.param ?? (current.value.route === 'log/photo' ? 'photo' : 'lessons')) as keyof typeof SOON;
  const item = SOON[key] ?? SOON.lessons;
  const Icon = item.Icon;
  return (
    <div class="screen">
      <TopBar title={item.title} subtitle="Coming soon" backTo={() => back(key === 'photo' ? 'log' : 'learn')} />
      <div class="card hero empty" style={{ padding: '40px 24px' }}>
        <div style={{ width: '96px', height: '96px', borderRadius: '22px', background: 'var(--surface-2)', display: 'grid', placeItems: 'center', margin: '0 auto 20px' }}>
          <Icon width={44} height={44} style={{ color: 'var(--ink)' }} />
        </div>
        <h2 style={{ marginBottom: '8px' }}>We're cooking this one</h2>
        <p style={{ maxWidth: '34ch' }}>{item.sub}</p>
      </div>
      {key === 'photo' && (
        <div class="card flat section">
          <p class="small muted">For now, Quick pick or Portion mode gets the same result, with no camera or data needed.</p>
          <button class="btn btn-primary btn-block" style={{ marginTop: '12px' }} onClick={() => go('log/quick', undefined, { replace: true })}>Use Quick pick</button>
        </div>
      )}
      {key === 'challenge' && (
        <div class="card flat section">
          <p class="eyebrow">A taste of it</p>
          <div class="row" style={{ marginTop: '8px' }}>
            <FoodIcon name="chunks" size={40} /><FoodIcon name="groundnut" size={40} />
            <p class="small muted grow">A handful of soya chunks plus a sachet of groundnuts is about {fmtRange(itemsProtein([{ foodId: 'soya_chunks', portionId: 'handful', qty: 1, eaten: 1 }, { foodId: 'groundnuts', portionId: 'sachet', qty: 1, eaten: 1 }]))} of protein for under ₦500.</p>
          </div>
          <button class="btn btn-soft btn-block" style={{ marginTop: '12px' }} onClick={() => go('suggestions')}>See today's ₦500 ideas</button>
        </div>
      )}
      <Footnote />
    </div>
  );
}
