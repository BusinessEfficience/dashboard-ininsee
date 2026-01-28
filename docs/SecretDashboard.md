# Secret Dashboard - Technical Documentation

> **Last Updated:** 28-01-2026 ; 12:30  
> **Status:** ✅ Fully Implemented  
> **Related:** [`docs/ImplementationPlan.md`](docs/ImplementationPlan.md) • [`docs/next.md`](docs/next.md)

---

## Changelog

| Date | Changes |
|------|---------|
| 28-01-2026 | Removed "Taux Horaire" section from dashboard; Added reference to new [Triple-Click Counter Feature](docs/next.md#-triple-click-counter-feature) |
| 27-01-2026 | Initial documentation |

---

## ⚠️ Changes Notice

### Taux Horaire Section Removed
The "Taux Horaire" (Hourly Rate) section has been **removed from the Secret Dashboard** and relocated to a new secret feature - the **Triple-Click Counter** on the "English" language link.

### Migration to New Feature
The hourly rate functionality is now available through a more discreet and fun hidden feature:

📖 **See:** [Triple-Click Counter Feature](docs/next.md#-triple-click-counter-feature) for full documentation of the new implementation.

**Key Changes:**
- ✅ **Removed from Dashboard:** The hourly rate input fields, start/stop buttons, and "show in title" checkbox
- ✅ **New Location:** English language link (top-right corner)
- ✅ **New Rate:** 17 EUR/hour (same as before)
- ✅ **New Trigger:** Triple-click sequence (300ms threshold)

## Table of Contents

1. [Overview](#overview)
2. [User Interaction Flow](#user-interaction-flow)
3. [Technical Architecture](#technical-architecture)
4. [Session State Management](#session-state-management)
5. [Supabase Configuration](#supabase-configuration)
6. [CSS Styling](#css-styling)
7. [JavaScript Functions](#javascript-functions)
8. [Security Considerations](#security-considerations)
9. [Configuration Requirements](#configuration-requirements)

---

## Overview

The Secret Dashboard is a hidden, overlay-based administrative interface integrated into `index.html`. It is triggered by a specific 3-click sequence on the "Télécharger les documents" link and requires authentication via a password.

### Key Features
- **Hidden Trigger**: 3-click sequence on download link
- **Authentication**: Password-protected access ("INSEE_SECRET_2026")
- **Memory-Only Session**: No localStorage, sessionStorage, or cache persistence
- **Supabase Integration**: Cloud data storage for logs
- **Metrics Dashboard**: Weekly/daily entry counts and average scores
- **📖 Hourly Rate Tracker**: Moved to [Triple-Click Counter Feature](docs/next.md#-triple-click-counter-feature)

---

## User Interaction Flow

### Phase 1: Trigger Sequence
```
Click 1 → Counter shows "(1/3)" next to download link
Click 2 → Counter shows "(2/3)" next to download link
Click 3 → Password field appears, counter hidden, navigation prevented
```

### Phase 2: Authentication
```
1. User enters password "INSEE_SECRET_2026"
2. User presses ENTER key
3. System validates password
   - SUCCESS: Dashboard overlay appears, success message shown
   - FAILURE: Error message shown, resets after 2 seconds
```

### Phase 3: Dashboard Access
```
1. Dashboard overlay covers entire viewport (z-index: 10000)
2. User can:
   - Add new log entries
   - View metrics (expandable section)
   - 📖 Track hourly rate (moved to Triple-Click Counter)
   - View and delete log history
3. Click "Déconnexion" to return to main page
```

### Phase 4: Session Reset
```
- Page refresh → Dashboard locked (session in memory only)
- 4th click on download link → Resets counter and hides password field
- Logout → Returns to main page, resets all state
```

---

## Technical Architecture

### File Structure
```
index.html
├── <head>
│   └── <style> (CSS for secret dashboard)
├── <body>
│   ├── Download Link Section (lines 874-884)
│   │   ├── <a id="downloadLink">
│   │   ├── <span id="clickCounter">
│   │   └── <div id="passwordField">
│   ├── Secret Dashboard Overlay (lines 1194-1280)
│   │   ├── Header with logout button
│   │   ├── Metrics section
│   │   ├── Hourly rate tracker
│   │   ├── Log entry form
│   │   └── Logs table
│   └── <script> (JavaScript logic)
```

### Key HTML Elements

| Element ID | Location | Purpose |
|------------|----------|---------|
| `downloadLink` | Line 875 | Trigger link for download documents |
| `clickCounter` | Line 877 | Shows click count (1/3), (2/3) |
| `passwordField` | Line 879 | Hidden password input field |
| `passwordInput` | Line 880 | Password input field (ENTER key to submit) |
| `secretDashboard` | Line 1195 | Main dashboard overlay |
| `logoutBtn` | Line 1198 | Logout button |
| `logForm` | Line 1247 | Log entry form |
| `logsTableBody` | Line 1275 | Table body for log entries |
| `metricsToggle` | Line 1205 | Toggle button for metrics |
| `📖 hourlyRate` | — | Moved to [Triple-Click Counter](docs/next.md#-triple-click-counter-feature) |
| `📖 startRateBtn` | — | Moved to [Triple-Click Counter](docs/next.md#-triple-click-counter-feature) |
| `📖 stopRateBtn` | — | Moved to [Triple-Click Counter](docs/next.md#-triple-click-counter-feature) |
| `📖 showInTitleCheckbox` | — | Moved to [Triple-Click Counter](docs/next.md#-triple-click-counter-feature) |

---

## Session State Management

### Memory-Only Variables
```javascript
let isLoggedIn = false;          // Authentication state
let clickCount = 0;              // Click counter for trigger
let rateInterval = null;         // Timer interval for rate tracker
let secondsElapsed = 0;          // Seconds tracked
let originalTitle = document.title; // Preserved original title
```

### Persistence Policy
- **NO** localStorage
- **NO** sessionStorage
- **NO** cache
- Session state exists only in JavaScript memory
- Page refresh = session reset

---

## Supabase Configuration

### Table Schema
```sql
CREATE TABLE logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamptz DEFAULT now(),
    log_date date,
    log_time time,
    entry_id text,
    score numeric
);
```

### CDN Integration
```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
```

### Client Initialization
```javascript
const supabaseUrl = 'https://your-project.supabase.co';
const supabaseKey = 'your-anon-key';
let supabase;
try {
    supabase = window.supabase.createClient(supabaseUrl, supabaseKey);
} catch (e) {
    console.warn('Supabase client initialization failed - running in offline mode');
}
```

### CRUD Operations

#### Create (addLog)
```javascript
async function addLog(logData) {
    // Add to local memory
    window.dashboardLogs.push({
        id: crypto.randomUUID(),
        created_at: new Date().toISOString(),
        ...logData
    });
    
    // Save to Supabase if available
    if (supabase) {
        await supabase.from('logs').insert([logData]);
    }
}
```

#### Read (getLogs)
```javascript
async function getLogs() {
    // Return from memory first
    if (window.dashboardLogs) {
        return window.dashboardLogs;
    }
    
    // Fetch from Supabase if available
    if (supabase) {
        const { data, error } = await supabase
            .from('logs')
            .select('*')
            .order('created_at', { ascending: false });
        return data;
    }
    
    return [];
}
```

#### Delete (deleteLog)
```javascript
async function deleteLog(id) {
    // Remove from memory
    window.dashboardLogs = window.dashboardLogs.filter(log => log.id !== id);
    
    // Delete from Supabase if available
    if (supabase) {
        await supabase.from('logs').delete().eq('id', id);
    }
    
    loadLogs();
    updateMetrics();
}
```

---

## CSS Styling

### Color Palette
| Color | Hex | Usage |
|-------|-----|-------|
| Insee Blue | `#0066cc` | Primary accent, headers, borders |
| Insee Grey | `#f5f5f5` | Background |
| White | `#ffffff` | Section backgrounds |
| Red | `#cc0000` | Logout button |

### Key CSS Classes

```css
.secret-dashboard-hidden { display: none !important; }
.secret-dashboard { display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background-color: #f5f5f5; z-index: 10000; overflow-y: auto; }
.secret-dashboard.active { display: block; }
.dashboard-header { background: white; padding: 20px 40px; border-bottom: 3px solid #0066cc; }
.dashboard-section { background: white; padding: 25px; margin-bottom: 25px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); border-left: 4px solid #0066cc; }
.logout-btn { background-color: #cc0000; color: white; padding: 8px 16px; border: none; border-radius: 3px; }
.hidden-password-field { display: none; }
.hidden-password-field.visible { display: block; }
```

---

## JavaScript Functions

### Event Handlers

| Function | Trigger | Purpose |
|----------|---------|---------|
| `handleDownloadClick` | Click on download link | Manage click counter and password field visibility |
| `checkPassword` | ENTER key on password input | Validate password and show dashboard |
| `handleLogout` | Click on "Déconnexion" button | Reset session and hide dashboard |
| `handleLogSubmit` | Form submission | Add new log entry |
| `toggleMetrics` | Click on metrics toggle | Show/hide metrics section |
| `📖 startRateTracker` | — | Moved to [Triple-Click Counter](docs/next.md#-triple-click-counter-feature) |
| `📖 stopRateTracker` | — | Moved to [Triple-Click Counter](docs/next.md#-triple-click-counter-feature) |
| `📖 updateTitle` | — | Moved to [Triple-Click Counter](docs/next.md#-triple-click-counter-feature) |

### Utility Functions

| Function | Purpose |
|----------|---------|
| `loadLogs()` | Render log entries table |
| `updateMetrics()` | Calculate and display weekly/daily stats |
| `addLog(logData)` | Add new log entry to memory and Supabase |
| `getLogs()` | Retrieve logs from memory or Supabase |
| `deleteLog(id)` | Delete log entry from memory and Supabase |

---

## Security Considerations

### Current Implementation
1. **Hardcoded Password**: "INSEE_SECRET_2026" stored in JavaScript
2. **Client-Side Validation**: Password check performed in browser
3. **No Encryption**: Data transmitted in plain text to Supabase
4. **Memory-Only Session**: No persistent authentication token

### Limitations
- Password visible in source code
- No HTTPS enforcement
- No rate limiting on authentication attempts
- Supabase credentials visible in source code

### Recommendations for Production
- Move password to server-side validation
- Implement proper authentication (OAuth, JWT)
- Use environment variables for credentials
- Enable Supabase RLS (Row Level Security)
- Add rate limiting on authentication attempts

---

## Configuration Requirements

### Supabase Setup
1. Create a Supabase project at https://supabase.com
2. Create the `logs` table with the schema defined above
3. Enable Row Level Security (RLS) policies
4. Copy the project URL and anon key

### Required Configuration
```javascript
const supabaseUrl = 'https://your-project.supabase.co';  // REPLACE
const supabaseKey = 'your-anon-key';  // REPLACE
```

### Optional: Environment Variables
Create a `.env` file (not committed to version control):
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
```

---

## Testing Checklist

- [ ] Click download link 3 times → Password field appears
- [ ] Enter wrong password → Error message shown, resets after 2 seconds
- [ ] Press ENTER key → Dashboard overlay appears
- [ ] Add a log entry → Entry appears in table and metrics update
- [ ] Delete a log entry → Entry removed from table and metrics update
- [ ] 📖 Start hourly rate tracker → See [Triple-Click Counter](docs/next.md#testing-checklist)
- [ ] 📖 Enable "show in title" → See [Triple-Click Counter](docs/next.md#testing-checklist)
- [ ] Refresh page → Dashboard locked (session reset)
- [ ] Click logout → Return to main page, state reset
- [ ] Click download link 4th time → Counter resets, password field hidden

---

## Related Files

- [`index.html`](index.html) - Main implementation file
- [`docs/ImplementationPlan.md`](docs/ImplementationPlan.md) - Original implementation plan
- [`docs/Changelog/Code/`](docs/Changelog/Code/) - Detailed code changes log
