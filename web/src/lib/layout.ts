// Physical Voyager base layer, transcribed from the Oryx/QMK export
// (zsa_voyager_nD6YQ_m5JaXj_i-don-t-know-colmak-dh_source.zip, layer 0).
// Colemak-DH legends, German host symbols, hold-tap mods and LT layer-taps.
// The ZIP is a build-time source only; nothing is loaded from it at runtime.

export type Half = 'L' | 'R';

export interface PhysKey {
  /** Stable id, e.g. "L-R2C4" or "L-T1". */
  id: string;
  half: Half;
  /** Base legend shown in the keycap corner. Empty string = unassigned (KC_NO). */
  legend: string;
  /** Hold-tap modifier or layer-tap hint, e.g. "CTL", "LT4". Shown small. */
  tap?: string;
  row: number; // 0..3 matrix rows
  col: number; // 0..5
  thumb: boolean;
  thumbIndex?: number; // 0 | 1
}

const K = (
  half: Half,
  row: number,
  col: number,
  legend: string,
  tap?: string,
): PhysKey => ({
  id: `${half}-R${row}C${col}`,
  half,
  legend,
  tap,
  row,
  col,
  thumb: false,
});

const T = (half: Half, index: number, legend: string): PhysKey => ({
  id: `${half}-T${index}`,
  half,
  legend,
  row: 4,
  col: index,
  thumb: true,
  thumbIndex: index,
});

export const LEFT_KEYS: PhysKey[] = [
  K('L', 0, 0, ''), K('L', 0, 1, ''), K('L', 0, 2, ''), K('L', 0, 3, ''), K('L', 0, 4, ''), K('L', 0, 5, ''),
  K('L', 1, 0, 'ESC'), K('L', 1, 1, 'Q'), K('L', 1, 2, 'W', 'LT5'), K('L', 1, 3, 'F', 'LT4'), K('L', 1, 4, 'P', 'LT8'), K('L', 1, 5, 'B', 'LT9'),
  K('L', 2, 0, 'TAB'), K('L', 2, 1, 'A', 'GUI'), K('L', 2, 2, 'R', 'ALT'), K('L', 2, 3, 'S', 'SFT'), K('L', 2, 4, 'T', 'CTL'), K('L', 2, 5, 'G'),
  K('L', 3, 0, 'MO10'), K('L', 3, 1, 'Z', 'LT6'), K('L', 3, 2, 'X'), K('L', 3, 3, 'C'), K('L', 3, 4, 'D'), K('L', 3, 5, 'V'),
];

export const RIGHT_KEYS: PhysKey[] = [
  K('R', 0, 0, ''), K('R', 0, 1, ''), K('R', 0, 2, ''), K('R', 0, 3, ''), K('R', 0, 4, ''), K('R', 0, 5, ''),
  K('R', 1, 0, 'J'), K('R', 1, 1, 'L', 'CTL'), K('R', 1, 2, 'U', 'RSFT'), K('R', 1, 3, 'Y', 'GUI'), K('R', 1, 4, '-'), K('R', 1, 5, '+'),
  K('R', 2, 0, 'M'), K('R', 2, 1, 'N'), K('R', 2, 2, 'E'), K('R', 2, 3, 'I'), K('R', 2, 4, 'O'), K('R', 2, 5, '#', 'LT7'),
  K('R', 3, 0, 'K'), K('R', 3, 1, 'H'), K('R', 3, 2, ','), K('R', 3, 3, '.'), K('R', 3, 4, 'F13'), K('R', 3, 5, 'MO3'),
];

export const LEFT_THUMBS: PhysKey[] = [T('L', 0, 'SPACE'), T('L', 1, 'BKSP')];
export const RIGHT_THUMBS: PhysKey[] = [T('R', 0, 'DEL'), T('R', 1, 'ENTER')];

export const ALL_KEYS: PhysKey[] = [...LEFT_KEYS, ...LEFT_THUMBS, ...RIGHT_KEYS, ...RIGHT_THUMBS];

export const KEY_BY_ID: Record<string, PhysKey> = Object.fromEntries(ALL_KEYS.map((k) => [k.id, k]));

// Letter legend -> physical key id (uppercase and lowercase share the key).
export const LETTER_KEY: Record<string, string> = {};
for (const k of ALL_KEYS) {
  if (/^[A-Z]$/.test(k.legend)) LETTER_KEY[k.legend] = k.id;
}

// Hold-tap modifier ingredients, both alternatives where they exist.
// Ctrl-e highlights E plus both of these (plan example).
export const CTRL_KEYS = ['L-R2C4', 'R-R1C1']; // T and L
export const SHIFT_KEYS = ['L-R2C3', 'R-R1C2']; // S and U
export const ALT_KEYS = ['L-R2C2']; // R
export const GUI_KEYS = ['L-R2C1', 'R-R1C3']; // A and Y

export const SPACE_ID = 'L-T0';
export const BKSP_ID = 'L-T1';
export const ENTER_ID = 'R-T1';

// Symbol slots reached by holding F (LT4 -> symbols layer) plus the slot key.
export const HOLD_F_ID = 'L-R1C3';
export const EXLM_SLOT_ID = 'R-R2C3'; // ! on the symbols layer
export const QST_SLOT_ID = 'R-R2C2'; // ? on the symbols layer
export const UNDERSCORE_SLOT_ID = 'R-R3C5'; // _ on the symbols layer

// Columnar stagger: per-column vertical offsets approximating the Voyager dish.
export const STAGGER_L = [16, 8, 2, 0, 6, 14];
export const STAGGER_R = [14, 6, 0, 2, 8, 16];

export const KEY_W = 52;
export const KEY_H = 52;
export const KEY_GAP = 6;
export const STEP = KEY_W + KEY_GAP;
