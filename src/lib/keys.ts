let seq = 0;
/** Short unique keys for draft items (stable across re-renders). */
export const newKey = () => `k${Date.now().toString(36)}${(seq++).toString(36)}`;
