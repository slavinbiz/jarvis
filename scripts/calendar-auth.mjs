#!/usr/bin/env node
/**
 * Google Calendar OAuth flow — runs a local server, captures callback, saves tokens
 */

import { createServer } from 'node:http';
import { createHash, randomBytes } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';

const CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;
const REDIRECT_URI = 'http://localhost:8080/callback';
const CREDENTIALS_FILE = '/home/agent/.claude/.credentials.json';
const MCP_KEY = 'google-calendar|5cc3ae4d874c4870';

const SCOPES = [
  'https://www.googleapis.com/auth/calendar',
  'https://www.googleapis.com/auth/calendar.events',
  'https://www.googleapis.com/auth/calendar.events.readonly',
  'https://www.googleapis.com/auth/calendar.readonly',
].join(' ');

// PKCE
const codeVerifier = randomBytes(32).toString('base64url');
const codeChallenge = createHash('sha256').update(codeVerifier).digest('base64url');
const state = randomBytes(16).toString('base64url');

const authUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth');
authUrl.searchParams.set('response_type', 'code');
authUrl.searchParams.set('client_id', CLIENT_ID);
authUrl.searchParams.set('redirect_uri', REDIRECT_URI);
authUrl.searchParams.set('scope', SCOPES);
authUrl.searchParams.set('state', state);
authUrl.searchParams.set('code_challenge', codeChallenge);
authUrl.searchParams.set('code_challenge_method', 'S256');
authUrl.searchParams.set('access_type', 'offline');
authUrl.searchParams.set('prompt', 'consent');
authUrl.searchParams.set('resource', 'https://calendarmcp.googleapis.com/mcp');

console.log('\n=== ОТКРОЙ ЭТУ ССЫЛКУ В БРАУЗЕРЕ ===\n');
console.log(authUrl.toString());
console.log('\n=====================================\n');
console.log('Жду авторизации...');

const server = createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost:8080');
  if (url.pathname !== '/callback') { res.end(); return; }

  const code = url.searchParams.get('code');
  const returnedState = url.searchParams.get('state');

  if (returnedState !== state) {
    res.end('State mismatch!');
    server.close();
    return;
  }

  res.end('<html><body><h2>✅ Авторизация успешна! Можно закрыть вкладку.</h2></body></html>');

  // Exchange code for tokens
  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      redirect_uri: REDIRECT_URI,
      grant_type: 'authorization_code',
      code_verifier: codeVerifier,
    }),
  });

  const tokens = await tokenRes.json();

  if (tokens.error) {
    console.error('Token error:', tokens);
    server.close();
    return;
  }

  // Save to credentials file
  const creds = JSON.parse(readFileSync(CREDENTIALS_FILE, 'utf8'));
  creds.mcpOAuth = creds.mcpOAuth || {};
  creds.mcpOAuth[MCP_KEY] = {
    ...(creds.mcpOAuth[MCP_KEY] || {}),
    accessToken: tokens.access_token,
    refreshToken: tokens.refresh_token,
    expiresAt: Date.now() + tokens.expires_in * 1000,
    tokenType: tokens.token_type,
    scope: tokens.scope,
  };
  writeFileSync(CREDENTIALS_FILE, JSON.stringify(creds, null, 2));

  console.log('✅ Токены сохранены! Перезапусти бота.');
  server.close();
});

server.listen(8080, () => console.log('Сервер запущен на порту 8080'));
