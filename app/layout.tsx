import type { Metadata } from "next";
import "./globals.css";
import "./portal.css";
import "./onboarding.css";
import "./contact.css";

export const metadata: Metadata = {
  title: { default: "MAKTAB X — Maktab hayoti bir joyda", template: "%s | MAKTAB X" },
  description: "O‘zbekiston maktablari uchun xavfsiz ta’lim platformasi.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="uz"><body>{children}</body></html>;
}
