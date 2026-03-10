# Night Notes - iOS Dream Journal

Premium dream journal with AI interpretations. **Veil** design direction.

## Quick Start with Codemagic (No Mac Required)

### 1. Push to GitHub
Create repo `github.com/liamwt-12/night-notes-ios` and push all files.

### 2. Run Supabase Schema
Paste `supabase-schema.sql` in Supabase SQL Editor.

### 3. Deploy API to Netlify
Push the `api/` folder to a Netlify site. Set env vars:
- `ANTHROPIC_API_KEY`
- `SUPABASE_URL`  
- `SUPABASE_SERVICE_ROLE_KEY`

### 4. Update Credentials
Edit `NightNotes/SupabaseClient.swift`:
```swift
private let supabaseURL = URL(string: "https://YOUR_PROJECT.supabase.co")!
private let supabaseKey = "YOUR_ANON_KEY"
private let baseURL = "https://YOUR_NETLIFY_SITE.netlify.app"
```

### 5. Set Up Codemagic
1. Go to codemagic.io → Add application → Your GitHub repo
2. Add environment variable: `APP_STORE_CONNECT_PRIVATE_KEY` (your .p8 file)
3. Push to main → Builds automatically → Uploads to TestFlight

### 6. Create IAP Products in App Store Connect
- `uk.nightnotes.tokens.3` — Consumable, £0.99
- `uk.nightnotes.tokens.10` — Consumable, £2.99  
- `uk.nightnotes.subscription.monthly` — Auto-renewable, £4.99/month

### 7. Add App Icon
Add 1024x1024 PNG named `AppIcon.png` to `NightNotes/Assets.xcassets/AppIcon.appiconset/`

---

## Project Structure
```
NightNotes/
├── NightNotesApp.swift       # Entry point
├── Theme.swift               # Design system (Veil)
├── Models.swift              # Data types
├── AuthManager.swift         # Sign in with Apple
├── SupabaseClient.swift      # Backend config
├── DreamStore.swift          # Dream state
├── PurchaseManager.swift     # StoreKit 2
└── Views/
    ├── OnboardingView.swift
    ├── MainTabView.swift
    ├── DreamEntryView.swift
    ├── ReflectionView.swift
    ├── JournalView.swift
    ├── SettingsView.swift
    └── PurchaseView.swift
```

## Pricing
- Free: 1 dream
- 3 tokens: £0.99
- 10 tokens: £2.99
- Unlimited: £4.99/month

## Your Credentials
- Team ID: `U5AU32RQ46`
- App Store Connect Key: `F5F4QC3YX7`
- Issuer ID: `c584f62c-5d0d-49f9-895d-de474583cbe8`
