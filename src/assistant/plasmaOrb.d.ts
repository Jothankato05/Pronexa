export interface OrbRenderer {
  draw(state: Record<string, unknown>): boolean;
  dispose(): void;
}
/** Returns null when WebGL 2 or the shaders are unavailable. */
export function createRenderer(canvas: HTMLCanvasElement): OrbRenderer | null;
