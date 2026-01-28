# Deployment Guide - INSEE Static Site with Supabase

## Prerequisites

1. **Supabase Account:** https://supabase.com
2. **Cloudflare Account:** https://cloudflare.com
3. **GitHub Account:** For repository hosting (recommended)

## Step 1: Supabase Setup

### 1.1 Create Supabase Project
1. Go to https://supabase.com
2. Click "New Project"
3. Configure:
   - **Name:** `insee-dashboard`
   - **Password:** Generate and save securely
   - **Region:** `eu-west-1` (Europe)
4. Wait for initialization (~2 minutes)

### 1.2 Run Database Setup
1. Go to Supabase Dashboard → SQL Editor
2. Open `supabase-setup.sql` from project root
3. Copy all content
4. Paste in SQL Editor and click "Run"
5. Verify: Settings → Tables should show `logs` and `metrics`

### 1.3 Get API Credentials
1. Go to Settings → API
2. Copy:
   - **Project URL** (e.g., `https://xyz123.supabase.co`)
   - **anon public** key (starts with `eyJ...`)

## Step 2: Cloudflare Pages Setup

### 2.1 Connect Repository
1. Go to https://dash.cloudflare.com
2. Select "Pages" → "Connect to Git"
3. Select your GitHub repository
4. Configure:
   - **Build command:** (leave empty for static site)
   - **Build output directory:** `/`

### 2.2 Add Environment Variables
1. In Cloudflare Pages → Your project → Settings
2. Go to "Environment variables"
3. Add:
   - **Name:** `PUBLIC_SUPABASE_URL`
     **Value:** Your Supabase project URL
   - **Name:** `PUBLIC_SUPABASE_ANON_KEY`
     **Value:** Your anon public key
4. Click "Save and Deploy"

### 2.3 Deploy
- Cloudflare automatically deploys on git push
- Or manually upload build files

## Step 3: Verify Deployment

### 3.1 Check Supabase Connection
Open browser console and run:
```javascript
testSupabaseConnection();
```

Expected output:
```
✅ Supabase connected successfully
{ status: 'connected', message: 'Connection successful' }
```

### 3.2 Test Dashboard Functionality
1. Navigate to deployed site
2. Trigger secret dashboard (3-click sequence)
3. Add a test log entry
4. Verify it appears in the logs table
5. Check metrics update correctly

## Troubleshooting

### Supabase Not Connecting
- Verify environment variables in Cloudflare Pages
- Check RLS policies are enabled
- Test connection: `testSupabaseConnection()` in console

### Deployment Failed
- Check Cloudflare Pages build logs
- Verify no syntax errors in HTML/JS
- Ensure all files are committed to git

### RLS Errors
- Go to Supabase Settings → API
- Verify Row Level Security is enabled
- Check policy syntax in SQL Editor

## Security Checklist

- [ ] Anon key used (not service role key)
- [ ] RLS policies enabled on all tables
- [ ] No credentials in source code
- [ ] Environment variables configured
- [ ] .gitignore includes .env files
- [ ] HTTPS enforced automatically

## Cost (Free Tier)

| Service | Free Limit | Cost if Exceeded |
|---------|------------|------------------|
| Cloudflare Pages | Unlimited | $0 |
| Supabase | 500 MB DB, 50K MAU | $25/month |
| Domain | ~$12/year | Optional |

**Total Monthly Cost: $0** (within free tiers)

## Files Created/Modified

| File | Purpose |
|------|---------|
| `supabase-setup.sql` | Database schema and RLS policies |
| `.env.example` | Environment variable template |
| `.gitignore` | Excludes sensitive files |
| `index.html` | Updated Supabase integration |

## Environment Variables Required

```env
PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
```

## Next Steps

1. Set up custom domain (optional)
2. Configure SSL certificates (automatic with Cloudflare)
3. Set up monitoring and alerts
4. Regular backups of Supabase data
