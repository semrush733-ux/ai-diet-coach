import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: "#168B72",
          dark: "#106D5B",
        },
        ink: "#17212B",
        muted: "#64748B",
      },
    },
  },
  plugins: [],
};
export default config;
