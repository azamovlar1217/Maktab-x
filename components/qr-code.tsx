import { encodeQr } from "@/lib/qrcode";

export function QrCode({ value, label }: { value: string; label?: string }) {
  const matrix = encodeQr(value);
  const quiet = 4; const size = matrix.length + quiet * 2;
  const path: string[] = [];
  matrix.forEach((row, y) => row.forEach((dark, x) => { if (dark) path.push(`M${x + quiet},${y + quiet}h1v1h-1z`); }));
  return <svg className="qr-code" viewBox={`0 0 ${size} ${size}`} role="img" aria-label={label || "Bir martalik CoinShop QR kodi"} shapeRendering="crispEdges"><rect width={size} height={size} fill="white"/><path d={path.join("")} fill="#10264d"/></svg>;
}
