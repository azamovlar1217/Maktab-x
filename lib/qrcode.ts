/** Small QR version 3-L encoder for short, opaque redemption tokens (up to 53 UTF-8 bytes). */
export function encodeQr(value: string): boolean[][] {
  const bytes = Array.from(new TextEncoder().encode(value));
  if (bytes.length > 53) throw new Error("QR kodi matni juda uzun.");
  const dataBits: number[] = [];
  const push = (n: number, width: number) => { for (let i = width - 1; i >= 0; i--) dataBits.push((n >>> i) & 1); };
  push(4, 4); push(bytes.length, 8); bytes.forEach(b => push(b, 8));
  const capacity = 55 * 8;
  for (let i = 0; i < Math.min(4, capacity - dataBits.length); i++) dataBits.push(0);
  while (dataBits.length % 8) dataBits.push(0);
  const data: number[] = [];
  for (let i = 0; i < dataBits.length; i += 8) data.push(dataBits.slice(i, i + 8).reduce((n, b) => (n << 1) | b, 0));
  for (let pad = 0; data.length < 55; pad++) data.push(pad % 2 ? 0x11 : 0xec);
  const ecc = reedSolomon(data, 15);
  const words = [...data, ...ecc];
  const size = 29;
  const matrix: (boolean | null)[][] = Array.from({ length: size }, () => Array(size).fill(null));
  const put = (x: number, y: number, dark: boolean) => { if (x >= 0 && y >= 0 && x < size && y < size) matrix[y][x] = dark; };
  const finder = (cx: number, cy: number) => {
    for (let dy = -4; dy <= 4; dy++) for (let dx = -4; dx <= 4; dx++) {
      const d = Math.max(Math.abs(dx), Math.abs(dy)); put(cx + dx, cy + dy, d !== 2 && d !== 4);
    }
  };
  finder(3, 3); finder(size - 4, 3); finder(3, size - 4);
  for (let i = 0; i < size; i++) {
    if (matrix[6][i] === null) put(i, 6, i % 2 === 0);
    if (matrix[i][6] === null) put(6, i, i % 2 === 0);
  }
  for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) {
    const d = Math.max(Math.abs(dx), Math.abs(dy)); put(22 + dx, 22 + dy, d !== 1);
  }
  // Format information: error correction L, mask 0.
  const format = 0x77c4;
  for (let i = 0; i < 15; i++) {
    const bit = ((format >>> i) & 1) !== 0;
    if (i < 6) put(8, i, bit); else if (i < 8) put(8, i + 1, bit); else put(8, size - 15 + i, bit);
    if (i < 8) put(size - i - 1, 8, bit); else if (i < 9) put(15 - i, 8, bit); else put(15 - i - 1, 8, bit);
  }
  put(8, size - 8, true);
  const stream = words.flatMap(w => Array.from({ length: 8 }, (_, i) => (w >>> (7 - i)) & 1));
  let bitIndex = 0;
  for (let right = size - 1; right >= 1; right -= 2) {
    if (right === 6) right--;
    for (let vert = 0; vert < size; vert++) {
      const y = ((right + 1) & 2) === 0 ? size - 1 - vert : vert;
      for (let j = 0; j < 2; j++) {
        const x = right - j;
        if (matrix[y][x] === null) { const raw = bitIndex < stream.length ? stream[bitIndex++] === 1 : false; put(x, y, raw !== ((x + y) % 2 === 0)); }
      }
    }
  }
  return matrix.map(row => row.map(cell => cell === true));
}

function reedSolomon(data: number[], degree: number): number[] {
  const multiply = (x: number, y: number) => {
    let z = 0;
    for (let i = 7; i >= 0; i--) { z = (z << 1) ^ ((z >>> 7) * 0x11d); if (((y >>> i) & 1) !== 0) z ^= x; }
    return z;
  };
  let generator = [1]; let root = 1;
  for (let i = 0; i < degree; i++) { const next = Array(generator.length + 1).fill(0); generator.forEach((v, j) => { next[j] ^= v; next[j + 1] ^= multiply(v, root); }); generator = next; root = multiply(root, 2); }
  const result = [...data, ...Array(degree).fill(0)];
  for (let i = 0; i < data.length; i++) { const factor = result[i]; if (factor) generator.forEach((v, j) => { result[i + j] ^= multiply(v, factor); }); }
  return result.slice(data.length);
}
