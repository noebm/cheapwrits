# WritMaxxer

Ranks Craftsman's Writs by estimated price per 100 reputation.

- `/wmax` — Show help and addon version.
- `/wmax scan` — Scan auction prices. Keep the auction house open until complete.
- `/wmax replay` — Recalculate the saved snapshot, including after `/reload`.
- `/wmax results` — Open the current results.

Full scans are incompatible with other auction house addons doing full scans: they share a 15-minute cooldown and replace the same snapshot. Disable their automatic full scans when using WritMaxxer. Replay needs no new scan.
