import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "KLAESP Web",
  description: "KLAESP web application",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
