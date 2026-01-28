# Implementation Plan - Secret Dashboard Integration

## Overview
> **Status: ✅ FULLY IMPLEMENTED** - All 5 phases completed as of 27-01-2026

Integrate a hidden dashboard into `index.html` triggered by a specific click sequence. The dashboard will interact with a Supabase backend for data storage, adhering to the "no local storage/cache" constraint.

## 1. Trigger Mechanism
- **Element**: `<a>` tag with text "Télécharger les documents" (found at line 547).
- **Logic**: 
  - Track clicks on this specific link.
  - On the 3rd click, prevent default navigation and show a hidden password input field.
  - The password field will be styled to match the Insee bureaucratic aesthetic.

## 2. Authentication & Dashboard Access
- **Password**: "INSEE_SECRET_2026" (placeholder, to be confirmed or made configurable).
- **Transition**: Upon correct password, hide the main website content and display the `secret-dashboard` overlay.
- **Security**: Since no local storage is allowed, the session state (logged in or not) will be kept in memory only. Refreshing the page will lock the dashboard.

## 3. Data Architecture (Supabase)
- **Table**: `logs`
  - `id`: uuid (primary key)
  - `created_at`: timestamptz (default now())
  - `log_date`: date
  - `log_time`: time
  - `entry_id`: text (manually input)
  - `score`: numeric (manually input)
- **Access**: Use the Supabase JS client via CDN. API Key and URL will be hardcoded in the script (obfuscation is limited in pure client-side HTML, but fits the "discrete" requirement).

## 4. Dashboard Features
- **Log Entry Form**: Inputs for Date, Time (default to now), ID, and Score.
- **Metrics Section (Expandable)**:
  - Weekly/Daily entry counts.
  - Weekly average score.
  - *Future-proofing*: Structure data to allow hourly/daily peak analysis later.
- **Hourly Rate Tracker**:
  - Input for hourly rate.
  - Real-time incrementing counter (calculated per second).
  - Toggle to sync this counter with `document.title`.

## 5. UI/UX Styling
- **Theme**: Bureaucratic, minimalist, using the Insee color palette (Blue `#0066cc`, Grey `#f5f5f5`).
- **Layout**: Fixed overlay for the dashboard to completely hide the underlying `index.html` content when active.

## 6. Implementation Phases

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1 | ✅ COMPLETE | UI/UX - Inject CSS and HTML structure for the password field and dashboard shell |
| Phase 2 | ✅ COMPLETE | Trigger & Auth - Implement the click counter and password validation logic |
| Phase 3 | ✅ COMPLETE | Database Integration - Setup Supabase client and implement CRUD for logs |
| Phase 4 | ✅ COMPLETE | Dashboard Logic - Implement metrics calculation and the hourly rate tracker |
| Phase 5 | ✅ COMPLETE | Final Polish - Ensure style consistency and "discrete" behavior |

## 7. Files Modified
- `index.html`: Main target for injection (~1580 lines)

## 8. Changelog

### 27-01-2026 ; 13:42 - Full Implementation Complete
- All 5 phases implemented successfully
- Secret Dashboard feature fully functional
- Supabase integration with placeholder credentials
- Hourly rate tracker with real-time counter
- Expandable metrics section (weekly/daily entries, average score)
- Session state stored in memory only (NO localStorage, sessionStorage, or cache)
- Original title preserved: "pcs2020-3-Cadres et professions intellectuelles supérieures | Insee"

### Related Documentation
- See [`docs/SecretDashboard.md`](docs/SecretDashboard.md) for detailed technical documentation
- See [`docs/Changelog/Code/`](docs/Changelog/Code/) for detailed code changes
