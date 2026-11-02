# Agent & Developer Rules: RVSDesk

These rules are **MANDATORY** for every developer and AI agent working in this repository (`rvsdesk`).

---

## 1. UI/UX Language Standards — Strictly English Only

1. **Every interactive application string MUST be written in English.**
   - Application banners, cards, guidance labels, and instructions.
   - Status indicators, buttons, copy actions, tooltips, and dialogs.
   - Snackbars, toasts, and error alerts.
2. **Never introduce non-English (e.g. Malay) strings into the UI chrome.**

---

## 2. Branding & Remote Support Standards

- Scripts in `scripts/apply_branding.py` must maintain:
  - Clear customer guidance on `connection_page.dart` (stating: `"🛰️ RITHV SERVICES REMOTE SUPPORT — Please share your ID and One-Time Password with your technician."`).
  - 1-click credential copying (`[📋 Copy ID & Password]`) copying both ID and One-Time Password simultaneously into the clipboard.
  - Safe coexistence with upstream Flutter and RustDesk components.

---

## 3. Pre-Push Verification Protocol

Before pushing to `origin/main`:
1. `python -m py_compile scripts/apply_branding.py` must succeed without errors.
2. Verify all script syntax and git cleanliness before committing.

