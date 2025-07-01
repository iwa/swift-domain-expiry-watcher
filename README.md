# swift domain expiry watcher

Console application which checks domain name date expiry, with notification support.

- Set your list of watched domains with comma-separated list in env var `DOMAINS`
- Sends a notification 30 days, 14 days and 7 days before expiry
- Supports Telegram notification with env vars `TELEGRAM_NOTIFICATION`, `TELEGRAM_CHAT_ID` & `TELEGRAM_BOT_TOKEN`

> This project isn't meant to be used in production, it was a project to learn more about Swift