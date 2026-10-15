import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "AI Diet Coach — Admin",
  description: "Administration dashboard for AI Diet Coach",
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
