import type { JSX } from 'preact';

/* ───────────── UI icons (24px, stroke) ───────────── */

type P = JSX.SVGAttributes<SVGSVGElement>;
const ui = (d: JSX.Element) => (props: P) => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" {...props}>
    {d}
  </svg>
);

export const IHome = ui(<><path d="M4 11.5 12 5l8 6.5" /><path d="M6 10v8.5a1.5 1.5 0 0 0 1.5 1.5h9a1.5 1.5 0 0 0 1.5-1.5V10" /><path d="M10 20v-5h4v5" /></>);
export const IPlusCircle = ui(<><circle cx="12" cy="12" r="8.5" /><path d="M12 8.5v7M8.5 12h7" /></>);
export const IBulb = ui(<><path d="M9 18h6M10 21h4" /><path d="M12 3a6 6 0 0 0-3.6 10.8c.6.5 1 1.2 1.1 2V16h5v-.2c.1-.8.5-1.5 1.1-2A6 6 0 0 0 12 3Z" /></>);
export const IBook = ui(<><path d="M4 5.5A1.5 1.5 0 0 1 5.5 4H11v16H5.5A1.5 1.5 0 0 1 4 18.5Z" /><path d="M20 5.5A1.5 1.5 0 0 0 18.5 4H13v16h5.5a1.5 1.5 0 0 0 1.5-1.5Z" /></>);
export const ISettings = ui(<><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z" /></>);
export const ICheck = ui(<path d="m5 12.5 4.5 4.5L19 7.5" />);
export const IChevronRight = ui(<path d="m9 6 6 6-6 6" />);
export const IChevronLeft = ui(<path d="m15 6-6 6 6 6" />);
export const ISearch = ui(<><circle cx="11" cy="11" r="6.5" /><path d="m20 20-4.2-4.2" /></>);
export const IPlus = ui(<path d="M12 5v14M5 12h14" />);
export const IClose = ui(<path d="M6 6l12 12M18 6 6 18" />);
export const IInfo = ui(<><circle cx="12" cy="12" r="9" /><path d="M12 11v5M12 8h.01" /></>);
export const ILeaf = ui(<><path d="M5 19c0-8 5-13 15-14-1 10-6 15-14 15" /><path d="M5 19c3-4 6-6.5 9-8" /></>);
export const IPencil = ui(<><path d="M4 20h4L19 9a2.8 2.8 0 0 0-4-4L4 16Z" /><path d="m13.5 6.5 4 4" /></>);
export const ISparkle = ui(<><path d="M12 3v4M12 17v4M3 12h4M17 12h4" /><path d="m6 6 2 2M16 16l2 2M6 18l2-2M16 8l2-2" /></>);
export const ITrash = ui(<><path d="M4 7h16M10 11v6M14 11v6" /><path d="M6 7l1 12a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-12M9 7V4h6v3" /></>);
export const ICamera = ui(<><path d="M4 8.5A1.5 1.5 0 0 1 5.5 7h2l1.5-2.5h6L16.5 7h2A1.5 1.5 0 0 1 20 8.5v9a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 17.5Z" /><circle cx="12" cy="13" r="3.5" /></>);
export const IChat = ui(<><path d="M5 5h14a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H10l-5 4V6a1 1 0 0 1 1-1Z" /><path d="M9 10h6M9 13h4" /></>);
export const IGrid = ui(<><rect x="4" y="4" width="7" height="7" rx="2" /><rect x="13" y="4" width="7" height="7" rx="2" /><rect x="4" y="13" width="7" height="7" rx="2" /><rect x="13" y="13" width="7" height="7" rx="2" /></>);
export const ICloudOff = ui(<><path d="M3 3l18 18" /><path d="M8.5 7.2A5.5 5.5 0 0 1 17.6 10 4 4 0 0 1 20 17.2M16 18H7a4.5 4.5 0 0 1-1.6-8.7" /></>);
export const ICloud = ui(<path d="M7 18a4.5 4.5 0 0 1-.5-9A5.5 5.5 0 0 1 17.4 10 4 4 0 0 1 17 18Z" />);
export const IShield = ui(<><path d="M12 3 5 6v5c0 4.5 3 8.3 7 10 4-1.7 7-5.5 7-10V6Z" /><path d="m9 12 2 2 4-4" /></>);
export const IHeart = ui(<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10Z" />);
export const IDownload = ui(<><path d="M12 4v11M7 10l5 5 5-5" /><path d="M5 20h14" /></>);
export const IPhone = ui(<><rect x="7" y="3" width="10" height="18" rx="2.5" /><path d="M11 18h2" /></>);
export const IMap = ui(<><path d="M9 4 3.5 6v14L9 18l6 2 5.5-2V4L15 6Z" /><path d="M9 4v14M15 6v14" /></>);
export const ITrophy = ui(<><path d="M8 4h8v5a4 4 0 0 1-8 0Z" /><path d="M8 6H5a3 3 0 0 0 3 4M16 6h3a3 3 0 0 1-3 4M12 13v4M8.5 20h7M10 17h4" /></>);
export const ICalendar = ui(<><rect x="4" y="5" width="16" height="15" rx="2.5" /><path d="M4 10h16M9 3v4M15 3v4" /></>);
export const IRefresh = ui(<><path d="M20 11a8 8 0 0 0-14.3-4.9L4 8" /><path d="M4 4v4h4M4 13a8 8 0 0 0 14.3 4.9L20 16" /><path d="M20 20v-4h-4" /></>);
export const IMenu = ui(<path d="M4 7h16M4 12h16M4 17h10" />);
export const IArrowUpRight = ui(<path d="M7 17 17 7M8 7h9v9" />);
export const IMore = ui(<path d="M5 12h.01M12 12h.01M19 12h.01" stroke-width="3" />);
export const IScale = ui(<><path d="M12 4v16M5 20h14" /><path d="M5 8h14M7 8l-3 6a3 3 0 0 0 6 0ZM17 8l-3 6a3 3 0 0 0 6 0Z" /></>);
export const IUser = ui(<><circle cx="12" cy="8" r="3.5" /><path d="M5 20a7 7 0 0 1 14 0" /></>);
export const IBolt = ui(<path d="M13 3 5 13.5h6L10 21l8-10.5h-6Z" />);
export const IWallet = ui(<><path d="M4 7.5A2.5 2.5 0 0 1 6.5 5H18v3" /><rect x="4" y="8" width="16" height="11" rx="2.5" /><circle cx="16" cy="13.5" r="1" /></>);

/* ───────────── Food & portion illustrations (48px, soft fills) ───────────── */

const OUT = { stroke: '#4a4339', 'stroke-width': 1.8, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' } as const;

const C = {
  bean: '#c27a50', beanLight: '#e2a77d', rice: '#fffdf8', riceShade: '#efe6d6', jollof: '#e58a55', leaf: '#97c487', leafDark: '#5a9a68',
  ochre: '#efc86f', yolk: '#f2b84b', cream: '#fbf1dd', plate: '#ffffff', swallow: '#f1dc98', amala: '#9b8577', soupOrange: '#e9a548',
  soupGreen: '#86b46a', stew: '#d4683e', meat: '#a95e45', fish: '#9fb7c4', tin: '#c9d3d8', nut: '#d8ad73', tofu: '#f8efd8', okpa: '#efb04a',
  lentil: '#e8894e', bottle: '#fbf4e4', pack: '#ffffff', packShade: '#f1ebe1', plantain: '#f4b545', chicken: '#d98e4f', cup: '#e9e2d5',
};

const plateBase = (
  <>
    <ellipse cx="24" cy="32" rx="20" ry="8" fill={C.plate} {...OUT} />
    <ellipse cx="24" cy="31" rx="13" ry="4.5" fill="none" stroke="#e7dfd3" stroke-width="1.5" />
  </>
);
const bowlBase = (fill: string) => (
  <>
    <path d="M6 22h36c0 10-8 17-18 17S6 32 6 22Z" fill="#fff" {...OUT} />
    <ellipse cx="24" cy="22" rx="18" ry="4.5" fill={fill} {...OUT} />
  </>
);
const pack = (s: number) => (
  <g transform={`translate(24 40) scale(${s}) translate(-24 -40)`}>
    <path d="M7 24 11 9.5c.3-1 1.2-1.5 2.2-1.5h21.6c1 0 1.9.6 2.2 1.5L41 24" fill={C.packShade} {...OUT} />
    <path d="M9 22c3-4 6-3 8-1 2-3 6-4 8-1 3-3 6-2 8 0 2-2 5-2 6 2" fill={C.ochre} {...OUT} />
    <path d="M5 24h38l-3.2 13.2c-.3 1.6-1.6 2.8-3.3 2.8H11.5c-1.7 0-3-1.2-3.3-2.8Z" fill={C.pack} {...OUT} />
    <path d="M12 30h24" stroke="#e7dfd3" stroke-width="1.5" stroke-linecap="round" />
  </g>
);

const FOOD_ICONS: Record<string, JSX.Element> = {
  bean: (
    <>
      <ellipse cx="17" cy="28" rx="8.5" ry="5.5" transform="rotate(-25 17 28)" fill={C.bean} {...OUT} />
      <ellipse cx="31" cy="30" rx="8.5" ry="5.5" transform="rotate(20 31 30)" fill={C.beanLight} {...OUT} />
      <ellipse cx="24" cy="18" rx="8.5" ry="5.5" transform="rotate(-5 24 18)" fill={C.bean} {...OUT} />
      <path d="M22 17.5h3M15.5 27.5l2-1M30 29.5l2 .8" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".7" />
    </>
  ),
  ricebeans: (
    <>
      {plateBase}
      <path d="M10 30c0-8 6-13 14-13s14 5 14 13Z" fill={C.rice} {...OUT} />
      {[[16, 25], [21, 21], [27, 23], [32, 27], [24, 27], [19, 28], [29, 20]].map(([x, y]) => <ellipse cx={x} cy={y} rx="2" ry="1.4" fill={C.bean} />)}
    </>
  ),
  rice: (
    <>
      {plateBase}
      <path d="M10 30c0-8 6-13 14-13s14 5 14 13Z" fill={C.rice} {...OUT} />
      <path d="M17 24.5l1.5-1M23 21.5l1.6.4M29 25l1.2-1.3M21 27.5l1.6-.2M26.5 27l1.5.6" stroke={C.riceShade} stroke-width="2" stroke-linecap="round" />
    </>
  ),
  jollof: (
    <>
      {plateBase}
      <path d="M10 30c0-8 6-13 14-13s14 5 14 13Z" fill={C.jollof} {...OUT} />
      <path d="M17 24.5l1.5-1M23 21.5l1.6.4M29 25l1.2-1.3M21 27.5l1.6-.2" stroke="#f6b488" stroke-width="2" stroke-linecap="round" />
      <circle cx="30" cy="21" r="1.6" fill={C.leafDark} />
    </>
  ),
  moimoi: (
    <>
      <path d="M8 30c2-11 9-18 16-18s14 7 16 18c-4 5-10 7-16 7s-12-2-16-7Z" fill={C.leaf} {...OUT} />
      <path d="M13 28c1.5-7 6-11 11-11s9.5 4 11 11c-3 3-7 4-11 4s-8-1-11-4Z" fill="#e9906a" {...OUT} />
      <path d="M24 12v4" {...OUT} />
      <circle cx="20" cy="25" r="1.3" fill="#fff" opacity=".6" />
    </>
  ),
  akara: (
    <>
      {[[15, 28], [33, 28], [24, 20]].map(([x, y]) => (
        <g>
          <circle cx={x} cy={y} r="9" fill="#d99a4e" {...OUT} />
          <circle cx={x - 3} cy={y - 2} r="1.1" fill="#a86a2a" />
          <circle cx={x + 2.5} cy={y + 1} r="1.1" fill="#a86a2a" />
          <circle cx={x} cy={y + 4} r="1" fill="#a86a2a" />
        </g>
      ))}
    </>
  ),
  soy: (
    <>
      <path d="M8 31c4-9 12-15 22-17 4-1 9 0 10 3s-2 6-6 8c-8 4-16 7-26 6Z" fill={C.leaf} {...OUT} />
      <circle cx="20" cy="26" r="3.6" fill="#e9d79a" {...OUT} />
      <circle cx="27.5" cy="22.5" r="3.6" fill="#e9d79a" {...OUT} />
      <circle cx="34" cy="19" r="3" fill="#e9d79a" {...OUT} />
    </>
  ),
  chunks: (
    <>
      <path d="M8 26c0-4 3-7 7-6.5 2 .2 3 2 5 1.5 3-1 6 1 5.5 5-.5 4-4 6-8 6s-9-2-9.5-6Z" fill="#b98957" {...OUT} />
      <path d="M24 17c1-4 5-6 9-5s6 5 5 9-5 5-8 4-7-4-6-8Z" fill="#c99a68" {...OUT} />
      <path d="M26 33c1-3 4-4 7-3.5s5 3 4 6-4 4-7 3.5-5-3-4-6Z" fill="#a8784a" {...OUT} />
    </>
  ),
  tofu: (
    <>
      <path d="M8 22l10-5 12 4-10 5Z" fill="#fffaf0" {...OUT} />
      <path d="M8 22v11l12 5V26Z" fill={C.tofu} {...OUT} />
      <path d="M20 26l10-5v11l-10 6Z" fill="#efe1bd" {...OUT} />
      <path d="M28 18l8-3 6 3-8 3Z" fill="#fffaf0" {...OUT} />
      <path d="M28 18v7l6 3v-7ZM34 21l8-3v7l-8 3" fill="#efe1bd" {...OUT} />
    </>
  ),
  groundnut: (
    <>
      <path d="M17 9c5 0 8 4 7 8-.5 2 .5 3.5 2 5 3 3 4 7 1 10.5s-9 4-12.5 1-3.5-7-1.5-10c1.2-2 1.5-3.5.5-5.5C10.5 13.5 12 9 17 9Z" fill={C.nut} transform="rotate(-30 20 24)" {...OUT} />
      <path d="M14 15l3 1M13 20l3 .5M17 29l3 1.5M20 25l3 .5" stroke="#b78a52" stroke-width="1.4" stroke-linecap="round" transform="rotate(-30 20 24)" />
      <ellipse cx="35" cy="34" rx="5" ry="3.6" fill="#f0c9a0" {...OUT} />
    </>
  ),
  okpa: (
    <>
      <path d="M9 21c0-4 3-7 7-7h16c4 0 7 3 7 7v8c0 4-3 7-7 7H16c-4 0-7-3-7-7Z" fill={C.okpa} {...OUT} />
      <path d="M14 18c4 2 16 2 20 0" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".6" />
      <path d="M33 14l4-5M37 9l3 2" {...OUT} />
    </>
  ),
  lentil: (
    <>
      {bowlBase('#f0a06d')}
      {[[16, 21], [21, 23], [26, 21], [31, 22.5], [19, 19.5], [28, 19.5], [24, 18.5]].map(([x, y]) => <ellipse cx={x} cy={y} rx="2.4" ry="1.4" fill={C.lentil} stroke="#b4572a" stroke-width=".8" />)}
    </>
  ),
  bottle: (
    <>
      <path d="M19 6h10v5c0 1 4 3 4 7v19a4 4 0 0 1-4 4H19a4 4 0 0 1-4-4V18c0-4 4-6 4-7Z" fill={C.bottle} {...OUT} />
      <path d="M19 6h10v4H19Z" fill={C.leafDark} {...OUT} />
      <path d="M15 24h18v8H15Z" fill={C.leaf} opacity=".8" />
    </>
  ),
  noodles: (
    <>
      {bowlBase('#f3d58e')}
      <path d="M12 21c2-2 3 2 5 0s3 2 5 0 3 2 5 0 3 2 5 0 3 2 4 0" stroke="#c99a3c" stroke-width="1.6" fill="none" stroke-linecap="round" />
      <path d="M30 6l-6 16M35 7l-8 15" stroke="#8a6a4a" stroke-width="2" stroke-linecap="round" />
    </>
  ),
  bread: (
    <>
      <path d="M8 22c0-6 7-10 16-10s16 4 16 10c0 2-1.5 3-3 3v10c0 2-1.5 3-3 3H14c-1.5 0-3-1-3-3V25c-1.5 0-3-1-3-3Z" fill="#e8b46e" {...OUT} />
      <path d="M14 26v9M20 26v9M26 26v9M32 26v9" stroke="#c48a43" stroke-width="1.5" stroke-linecap="round" />
      <path d="M13 18c3-2 6-3 11-3" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity=".55" />
    </>
  ),
  swallow: (
    <>
      <path d="M8 34c0-11 7-19 16-19s16 8 16 19c0 2-2 4-4 4H12c-2 0-4-2-4-4Z" fill={C.swallow} {...OUT} />
      <path d="M21 15c0-3 1.5-5 3-5s3 2 3 5" fill="none" {...OUT} />
      <path d="M14 26c2-4 5-6 9-6.5" stroke="#fff" stroke-width="1.8" stroke-linecap="round" opacity=".6" />
      <path d="M8.5 33c6 2 25 2 31 0" stroke="#e7dfd3" stroke-width="1.4" />
    </>
  ),
  'swallow-dark': (
    <>
      <path d="M8 34c0-11 7-19 16-19s16 8 16 19c0 2-2 4-4 4H12c-2 0-4-2-4-4Z" fill={C.amala} {...OUT} />
      <path d="M21 15c0-3 1.5-5 3-5s3 2 3 5" fill="none" {...OUT} />
      <path d="M14 26c2-4 5-6 9-6.5" stroke="#fff" stroke-width="1.8" stroke-linecap="round" opacity=".4" />
    </>
  ),
  yam: (
    <>
      <path d="M7 27c0-5 4-8 10-8s10 3 10 8-4 8-10 8-10-3-10-8Z" fill="#fbf3dc" stroke="#8a6648" stroke-width="3" />
      <path d="M21 20c0-5 4-8 10-8s10 3 10 8-4 8-10 8-10-3-10-8Z" fill="#fbf3dc" stroke="#8a6648" stroke-width="3" />
      <circle cx="16" cy="27" r="1" fill="#e0cfa5" /><circle cx="31" cy="20" r="1" fill="#e0cfa5" />
    </>
  ),
  plantain: (
    <>
      {[[14, 28, -20], [25, 32, 10], [33, 22, 30], [21, 19, -5]].map(([x, y, r]) => (
        <g transform={`rotate(${r} ${x} ${y})`}>
          <ellipse cx={x} cy={y} rx="7.5" ry="5" fill={C.plantain} {...OUT} />
          <ellipse cx={x} cy={y} rx="4" ry="2.4" fill="#f8cf72" />
          <ellipse cx={x} cy={y} rx="7.5" ry="5" fill="none" stroke="#b5642a" stroke-width="1.2" stroke-dasharray="3 3" opacity=".5" />
        </g>
      ))}
    </>
  ),
  cup: (
    <>
      <path d="M10 14h24l-2.5 22a3 3 0 0 1-3 2.6H15.5a3 3 0 0 1-3-2.6Z" fill={C.cup} {...OUT} />
      <path d="M11 20h22l-.6 5H11.6Z" fill="#f2e6c7" />
      <path d="M34 18h3a4 4 0 0 1 0 8h-4" fill="none" {...OUT} />
      <circle cx="18" cy="22" r="1.4" fill={C.nut} /><circle cx="25" cy="23" r="1.4" fill={C.nut} />
    </>
  ),
  salad: (
    <>
      {plateBase}
      <path d="M11 29c2-6 7-10 13-10s11 4 13 10Z" fill="#f4ead2" {...OUT} />
      <path d="M15 26l5-3M21 27l6-4M27 27l5-3M18 23l3 3M26 22l3 3" stroke="#d8c08a" stroke-width="1.6" stroke-linecap="round" />
      <circle cx="17" cy="25" r="1.6" fill={C.leafDark} /><circle cx="30" cy="24" r="1.6" fill={C.stew} /><ellipse cx="24" cy="21.5" rx="2" ry="1.2" fill="#8a6a4a" />
    </>
  ),
  'soup-egusi': (
    <>
      {bowlBase(C.soupOrange)}
      {[[16, 21], [22, 23], [29, 21], [33, 22.5], [19, 23.5], [26, 20]].map(([x, y]) => <circle cx={x} cy={y} r="1.6" fill="#fbe7a8" />)}
      <path d="M14 22c2-1 3 1 5 0" stroke={C.leafDark} stroke-width="1.6" fill="none" stroke-linecap="round" />
    </>
  ),
  'soup-green': (
    <>
      {bowlBase(C.soupGreen)}
      <path d="M14 22c2-1.5 4 1 6-.5s4 1 6-.5 4 1 6-.5" stroke="#4f8a40" stroke-width="1.6" fill="none" stroke-linecap="round" />
    </>
  ),
  stew: (
    <>
      {bowlBase(C.stew)}
      <circle cx="18" cy="21.5" r="1.4" fill="#f4a07a" /><circle cx="27" cy="22.5" r="1.2" fill="#f4a07a" /><circle cx="31" cy="21" r="1" fill="#f4a07a" />
      <path d="M34 8 26 22" stroke="#8a6a4a" stroke-width="2.4" stroke-linecap="round" />
    </>
  ),
  egg: (
    <>
      <ellipse cx="18" cy="26" rx="9.5" ry="12" fill="#fff" {...OUT} />
      <circle cx="18" cy="28" r="4.8" fill={C.yolk} />
      <ellipse cx="33" cy="27" rx="8" ry="10" fill="#f4ead9" {...OUT} />
      <path d="M30 22c1-2 2-3 3.5-3.5" stroke="#fff" stroke-width="1.6" stroke-linecap="round" />
    </>
  ),
  chicken: (
    <>
      <path d="M30 9c-8-2-17 4-18 13-.6 5 2 9 6 10l6 2c4 1.2 8-1 10.5-4.5 3.5-5 4-13.5-4.5-20.5Z" fill={C.chicken} {...OUT} />
      <path d="M18 32l-5 5" stroke="#4a4339" stroke-width="5" stroke-linecap="round" />
      <path d="M18 32l-5 5" stroke="#fff8ec" stroke-width="2.6" stroke-linecap="round" />
      <circle cx="11" cy="38" r="2.6" fill="#fff8ec" {...OUT} /><circle cx="13.5" cy="40.5" r="2.4" fill="#fff8ec" {...OUT} />
      <path d="M22 15c2-2 5-2.5 7-2" stroke="#f3c08c" stroke-width="1.8" stroke-linecap="round" />
    </>
  ),
  beef: (
    <>
      <path d="M9 24c0-7 7-12 15-12 9 0 15 5 15 12 0 6-5 11-13 11-4 0-6-2-9-2-5 0-8-3-8-9Z" fill={C.meat} {...OUT} />
      <path d="M15 21c3-3 8-4 12-2M18 28c3 1 7 0 10-2" stroke="#d99a86" stroke-width="2" stroke-linecap="round" fill="none" />
      <ellipse cx="31" cy="24" rx="3" ry="2.4" fill="#f2d9c8" />
    </>
  ),
  fish: (
    <>
      <path d="M6 24c5-8 13-11 21-10 5 .6 9 4 11 10-2 6-6 9.4-11 10-8 1-16-2-21-10Z" fill={C.fish} {...OUT} />
      <path d="M36 24l7-7v14Z" fill={C.fish} {...OUT} />
      <circle cx="13" cy="22" r="1.6" fill="#4a4339" />
      <path d="M20 18c2 3 2 9 0 12M26 17c2 4 2 10 0 14" stroke="#7d97a5" stroke-width="1.4" fill="none" stroke-linecap="round" />
    </>
  ),
  tin: (
    <>
      <rect x="6" y="15" width="36" height="20" rx="8" fill={C.tin} {...OUT} />
      <rect x="10" y="18.5" width="28" height="13" rx="5.5" fill="#e5ecef" {...OUT} />
      <path d="M14 25c3-3 6-3 9 0s6 3 9 0" stroke="#7d97a5" stroke-width="1.5" fill="none" stroke-linecap="round" />
      <circle cx="38" cy="14" r="3" fill="none" {...OUT} />
    </>
  ),
  sachet: (
    <>
      <path d="M11 11l2.6 2 2.6-2 2.6 2 2.6-2 2.6 2 2.6-2 2.6 2 2.6-2 2.6 2 2.6-2V37c0 1.5-1 2.5-2.5 2.5h-21C12 39.5 11 38.5 11 37Z" fill="#fff" {...OUT} />
      <rect x="15" y="20" width="18" height="12" rx="3" fill="#7fa6d1" />
      <path d="M19 26h10" stroke="#fff" stroke-width="2" stroke-linecap="round" />
    </>
  ),
  handful: (
    <>
      <path d="M6 32c4-6 9-9 18-9s14 3 18 9c-4 4-10 6-18 6S10 36 6 32Z" fill="#f3e6cf" {...OUT} />
      {[[14, 29], [20, 26], [26, 27], [32, 29], [18, 31], [24, 31], [30, 32]].map(([x, y]) => <ellipse cx={x} cy={y} rx="2.8" ry="2" fill={C.nut} stroke="#a77a43" stroke-width=".9" />)}
    </>
  ),
  piece: (
    <>
      {plateBase}
      <path d="M15 28c0-4 4-7 9-7 6 0 9 3 9 7 0 2-3 3-9 3s-9-1-9-3Z" fill={C.meat} {...OUT} />
    </>
  ),
  'pack-sm': pack(0.74),
  'pack-md': pack(0.88),
  'pack-lg': pack(1.02),
  plate: (
    <>
      {plateBase}
      <path d="M12 30c0-6 5-10 12-10s12 4 12 10Z" fill={C.rice} {...OUT} />
      <path d="M26 21c4 .5 7.5 3 9 7" fill="none" stroke={C.stew} stroke-width="3" stroke-linecap="round" />
    </>
  ),
  bowl: <>{bowlBase(C.soupOrange)}<path d="M17 13c0-2 2-2 2-4M24 12c0-2 2-2 2-4M31 13c0-2 2-2 2-4" stroke="#c9bfae" stroke-width="1.6" stroke-linecap="round" fill="none" /></>,
  wrap: (
    <>
      <path d="M8 34c0-11 7-19 16-19s16 8 16 19c0 2-2 4-4 4H12c-2 0-4-2-4-4Z" fill={C.swallow} {...OUT} />
      <path d="M8 34c0-11 7-19 16-19s16 8 16 19" fill="none" stroke="#fff" stroke-width="1" opacity=".8" />
      <path d="M20 15c-1-3 0-6 4-7 4 1 5 4 4 7" fill="#fff" {...OUT} />
    </>
  ),
  spoon: (
    <>
      <path d="M12 30c-5-5-4-12 1-15s11-1 13 4c2 6-2 11-8 12" fill="#e1e6e8" {...OUT} />
      <path d="M17 29 40 40" stroke="#4a4339" stroke-width="5" stroke-linecap="round" />
      <path d="M17 29 40 40" stroke="#c9d3d8" stroke-width="2.4" stroke-linecap="round" />
      <path d="M13 22c1-3 4-4 7-3.5" stroke="#fff" stroke-width="1.6" stroke-linecap="round" />
    </>
  ),
  /* empty-state & onboarding illustrations */
  'empty-plate': (
    <>
      <ellipse cx="24" cy="30" rx="20" ry="9" fill="#fff" {...OUT} />
      <ellipse cx="24" cy="29" rx="12" ry="5" fill="none" stroke="#e7dfd3" stroke-width="1.6" />
      <path d="M6 11v8c0 1.5 1 2.5 2.5 2.5S11 20.5 11 19v-8M8.5 21.5V37" {...OUT} fill="none" />
      <path d="M41 11c-3 0-4.5 3-4.5 7s1.5 4 3 4V37" {...OUT} fill="none" />
    </>
  ),
};

export function FoodIcon({ name, class: cls, title, size, x, y }: { name: string; class?: string; title?: string; size?: number; x?: number; y?: number }) {
  const body = FOOD_ICONS[name] ?? FOOD_ICONS.bean;
  // Explicit size/x/y let the icon nest safely inside another <svg>.
  return (
    <svg viewBox="0 0 48 48" class={cls} width={size} height={size} x={x} y={y} role={title ? 'img' : undefined} aria-hidden={title ? undefined : 'true'} aria-label={title}>
      {body}
    </svg>
  );
}

/** A plate showing how much was eaten (1, .75, .5, .25), for the "how much" picker. */
export function EatenIcon({ fraction }: { fraction: number }) {
  const r = 14;
  const circ = 2 * Math.PI * r;
  return (
    <svg viewBox="0 0 48 48" aria-hidden="true">
      <circle cx="24" cy="24" r="21" fill="#fff" {...OUT} />
      <circle cx="24" cy="24" r={r} fill="none" stroke="#efe6d6" stroke-width={2 * r} />
      <circle cx="24" cy="24" r={r} fill="none" stroke={C.leafDark} stroke-width={2 * r} stroke-dasharray={`${circ * fraction} ${circ}`} transform="rotate(-90 24 24)" opacity=".85" />
      <circle cx="24" cy="24" r="21" fill="none" {...OUT} />
    </svg>
  );
}

/** Pronexa mark in the Asteria style: a geometric sprouting leaf and a seed. */
export function PronexaMark({ size = 120, class: cls }: { size?: number; class?: string }) {
  return (
    <svg viewBox="0 0 170 124" width={size} height={size * (124 / 170)} class={cls} role="img" aria-label="Pronexa">
      <defs>
        <linearGradient id="markGrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#ffffff" />
          <stop offset="1" stop-color="#e4efe0" />
        </linearGradient>
      </defs>
      <path d="M2 122C2 60 40 12 118 2c4 62-34 112-116 120Z" fill="url(#markGrad)" />
      <path d="M18 108C42 74 70 48 102 22" fill="none" stroke="#07101c" stroke-width="6" stroke-linecap="round" opacity=".18" />
      <rect x="122" y="74" width="47" height="49" rx="4" fill="#d9a441" />
    </svg>
  );
}
