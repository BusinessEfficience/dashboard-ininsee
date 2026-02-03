// Cloudflare Pages Function - injects Supabase credentials into HTML
// This runs on Cloudflare's edge before serving the page
// Environment variables: PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY (set in Pages Settings)

export async function onRequest(context) {
  const response = await context.next();
  
  // Only process HTML responses
  const contentType = response.headers.get('content-type') || '';
  if (!contentType.includes('text/html')) {
    return response;
  }

  const html = await response.text();
  
  // Only inject for the main index.html page
  if (!html.includes('SUPABASE CONFIGURATION')) {
    return response;
  }

  // Inject Supabase credentials as global JavaScript variables
  const supabaseScript = `<script>
  window.PUBLIC_SUPABASE_URL = "${context.env.PUBLIC_SUPABASE_URL || 'https://your-project.supabase.co'}";
  window.PUBLIC_SUPABASE_ANON_KEY = "${context.env.PUBLIC_SUPABASE_ANON_KEY || 'your-anon-key'}";
  </script>`;

  // Insert before closing </head> tag
  const modifiedHtml = html.replace('</head>', `${supabaseScript}</head>`);

  return new Response(modifiedHtml, {
    headers: response.headers,
  });
}
