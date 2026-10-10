'use client';

import React, { useState, useEffect } from 'react';

interface AuthInfo {
  app_name?: string;
  endpoint?: string;
  secret_hash?: string;
  salt?: string;
  version?: number;
  updated_at?: string;
}

export default function RVSDeskAdminPage() {
  const [currentAuth, setCurrentAuth] = useState<AuthInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);
  
  const [adminPin, setAdminPin] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showPin, setShowPin] = useState(false);

  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [copiedText, setCopiedText] = useState<string | null>(null);

  // Fetch current hash information on load
  const fetchCurrentAuth = async () => {
    try {
      setLoading(true);
      const res = await fetch('/rvsdesk-auth.json', { cache: 'no-store' });
      if (res.ok) {
        const data = await res.json();
        setCurrentAuth(data);
      }
    } catch (err) {
      console.error('Error checking auth:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCurrentAuth();
  }, []);

  // Generate strong random password
  const generateStrongPassword = () => {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    const special = '!@#$&*';
    const randPart = (len: number) => Array.from({ length: len }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
    const gen = `RVS-${randPart(4)}-${randPart(4)}${special[Math.floor(Math.random() * special.length)]}`;
    setNewPassword(gen);
    setShowPassword(true);
    setMessage(null);
  };

  // Copy text to clipboard
  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    setCopiedText(label);
    setTimeout(() => setCopiedText(null), 2500);
  };

  // Update password on server
  const handleUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    setMessage(null);

    if (!adminPin.trim()) {
      setMessage({ type: 'error', text: 'Please enter the Admin PIN for security.' });
      return;
    }
    if (!newPassword.trim()) {
      setMessage({ type: 'error', text: 'Please enter or generate a new password.' });
      return;
    }

    try {
      setUpdating(true);
      const res = await fetch('/rvsdesk-auth.json', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          adminPin: adminPin.trim(),
          newPassword: newPassword.trim(),
          salt: currentAuth?.salt || 'rvs_auth_sec_2026',
        }),
      });

      const result = await res.json();

      if (res.ok && result.success) {
        setMessage({
          type: 'success',
          text: `Success! Controller secret password is now active on server (Version ${result.version}).`,
        });
        setCurrentAuth({
          secret_hash: result.secret_hash,
          salt: result.salt,
          version: result.version,
          updated_at: result.updated_at,
        });
      } else {
        setMessage({ type: 'error', text: result.error || 'Failed to update password.' });
      }
    } catch (err: any) {
      setMessage({ type: 'error', text: err.message || 'Server connection error.' });
    } finally {
      setUpdating(false);
    }
  };

  return (
    <div style={styles.container}>
      {/* Background Glow */}
      <div style={styles.ambientGlow} />

      <div style={styles.card}>
        {/* Header */}
        <div style={styles.header}>
          <div style={styles.badge}>
            <span style={styles.statusDot} />
            <span>RVSDesk Relay Security</span>
          </div>
          <h1 style={styles.title}>Controller Password Manager</h1>
          <p style={styles.subtitle}>
            Change the secret password for RVSDesk controllers instantly without rebuilding .exe binaries.
          </p>
        </div>

        {/* Current Server Status */}
        <div style={styles.statusBox}>
          <div style={styles.statusRow}>
            <span style={styles.statusLabel}>Active Endpoint:</span>
            <span style={styles.statusValue}>https://service.danialharith.space/rvsdesk-auth.json</span>
          </div>
          <div style={styles.statusRow}>
            <span style={styles.statusLabel}>Current Hash:</span>
            <span style={styles.statusValueCode}>
              {loading ? 'Loading...' : currentAuth?.secret_hash ? `${currentAuth.secret_hash.slice(0, 16)}...${currentAuth.secret_hash.slice(-8)}` : 'None'}
            </span>
          </div>
          <div style={styles.statusRow}>
            <span style={styles.statusLabel}>Version / Updated:</span>
            <span style={styles.statusValue}>
              v{currentAuth?.version || 1} • {currentAuth?.updated_at ? new Date(currentAuth.updated_at).toLocaleTimeString() : 'New'}
            </span>
          </div>
        </div>

        {/* Alert Message */}
        {message && (
          <div style={message.type === 'success' ? styles.alertSuccess : styles.alertError}>
            <span>{message.type === 'success' ? '✅' : '⚠️'}</span>
            <span style={{ flex: 1, fontSize: '13px', lineHeight: 1.4 }}>{message.text}</span>
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleUpdate} style={styles.form}>
          {/* Admin PIN */}
          <div style={styles.inputGroup}>
            <div style={styles.labelRow}>
              <label style={styles.label}>Admin Security PIN</label>
              <span style={styles.labelHint}>(Default: rvsadmin2026)</span>
            </div>
            <div style={styles.inputWrapper}>
              <input
                type={showPin ? 'text' : 'password'}
                placeholder="Enter your Admin PIN"
                value={adminPin}
                onChange={(e) => setAdminPin(e.target.value)}
                style={styles.input}
                required
              />
              <button
                type="button"
                onClick={() => setShowPin(!showPin)}
                style={styles.toggleBtn}
                title="Show / Hide PIN"
              >
                {showPin ? '👁️' : '🙈'}
              </button>
            </div>
          </div>

          {/* New Password */}
          <div style={styles.inputGroup}>
            <div style={styles.labelRow}>
              <label style={styles.label}>New Secret Password</label>
              <button
                type="button"
                onClick={generateStrongPassword}
                style={styles.generateBtn}
              >
                ✨ Generate Random
              </button>
            </div>
            <div style={styles.inputWrapper}>
              <input
                type={showPassword ? 'text' : 'password'}
                placeholder="e.g. Secret@RVS2026"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                style={styles.input}
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                style={styles.toggleBtn}
                title="Show / Hide Password"
              >
                {showPassword ? '👁️' : '🙈'}
              </button>
              {newPassword && (
                <button
                  type="button"
                  onClick={() => copyToClipboard(newPassword, 'pass')}
                  style={styles.copyBtn}
                  title="Copy Password"
                >
                  {copiedText === 'pass' ? '✓ Copied' : '📋'}
                </button>
              )}
            </div>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={updating}
            style={updating ? styles.submitBtnDisabled : styles.submitBtn}
          >
            {updating ? 'Updating Server...' : '🚀 Update Secret Password Now'}
          </button>
        </form>

        {/* Footer Notes */}
        <div style={styles.footer}>
          <div style={styles.footerItem}>
            <span>🛡️</span>
            <span>All outgoing <strong>RVSDesk.exe</strong> controllers will immediately require this new password.</span>
          </div>
          <div style={styles.footerItem}>
            <span>👤</span>
            <span>Normal clients only receiving remote support are not affected.</span>
          </div>
        </div>
      </div>
    </div>
  );
}

// Gaya CSS Inline Moden (Dark Slate + Crimson Accent)
const styles: { [key: string]: React.CSSProperties } = {
  container: {
    minHeight: '100vh',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#070A0F',
    fontFamily: 'Inter, system-ui, -apple-system, sans-serif',
    color: '#F3F4F6',
    padding: '24px 16px',
    position: 'relative',
    overflow: 'hidden',
  },
  ambientGlow: {
    position: 'absolute',
    top: '15%',
    left: '50%',
    transform: 'translateX(-50%)',
    width: '500px',
    height: '350px',
    background: 'radial-gradient(circle, rgba(220, 38, 38, 0.15) 0%, rgba(0, 0, 0, 0) 70%)',
    pointerEvents: 'none',
  },
  card: {
    width: '100%',
    maxWidth: '520px',
    backgroundColor: 'rgba(15, 23, 42, 0.75)',
    backdropFilter: 'blur(16px)',
    WebkitBackdropFilter: 'blur(16px)',
    borderRadius: '20px',
    border: '1px solid rgba(255, 255, 255, 0.08)',
    boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.6), 0 0 0 1px rgba(220, 38, 38, 0.1)',
    padding: '32px 28px',
    zIndex: 1,
  },
  header: {
    marginBottom: '24px',
    textAlign: 'center',
  },
  badge: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '6px',
    backgroundColor: 'rgba(220, 38, 38, 0.12)',
    border: '1px solid rgba(220, 38, 38, 0.3)',
    color: '#F87171',
    padding: '4px 12px',
    borderRadius: '999px',
    fontSize: '11px',
    fontWeight: 600,
    letterSpacing: '0.5px',
    marginBottom: '12px',
  },
  statusDot: {
    width: '6px',
    height: '6px',
    borderRadius: '50%',
    backgroundColor: '#EF4444',
    boxShadow: '0 0 8px #EF4444',
  },
  title: {
    fontSize: '22px',
    fontWeight: 700,
    color: '#FFFFFF',
    margin: '0 0 8px 0',
    letterSpacing: '-0.3px',
  },
  subtitle: {
    fontSize: '13px',
    color: '#9CA3AF',
    margin: 0,
    lineHeight: 1.5,
  },
  statusBox: {
    backgroundColor: 'rgba(2, 6, 23, 0.5)',
    borderRadius: '12px',
    border: '1px solid rgba(255, 255, 255, 0.05)',
    padding: '12px 14px',
    marginBottom: '20px',
    display: 'flex',
    flexDirection: 'column',
    gap: '6px',
  },
  statusRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    fontSize: '12px',
  },
  statusLabel: {
    color: '#6B7280',
    fontWeight: 500,
  },
  statusValue: {
    color: '#D1D5DB',
    fontWeight: 500,
  },
  statusValueCode: {
    fontFamily: 'monospace',
    color: '#34D399',
    backgroundColor: 'rgba(16, 185, 129, 0.1)',
    padding: '2px 6px',
    borderRadius: '4px',
  },
  alertSuccess: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    backgroundColor: 'rgba(16, 185, 129, 0.12)',
    border: '1px solid rgba(16, 185, 129, 0.3)',
    color: '#6EE7B7',
    padding: '10px 14px',
    borderRadius: '10px',
    marginBottom: '18px',
  },
  alertError: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    backgroundColor: 'rgba(239, 68, 68, 0.12)',
    border: '1px solid rgba(239, 68, 68, 0.3)',
    color: '#FCA5A5',
    padding: '10px 14px',
    borderRadius: '10px',
    marginBottom: '18px',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '18px',
  },
  inputGroup: {
    display: 'flex',
    flexDirection: 'column',
    gap: '6px',
  },
  labelRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  label: {
    fontSize: '13px',
    fontWeight: 600,
    color: '#E5E7EB',
  },
  labelHint: {
    fontSize: '11px',
    color: '#6B7280',
  },
  generateBtn: {
    background: 'none',
    border: 'none',
    color: '#F87171',
    fontSize: '12px',
    fontWeight: 600,
    cursor: 'pointer',
    padding: '2px 4px',
    borderRadius: '4px',
  },
  inputWrapper: {
    position: 'relative',
    display: 'flex',
    alignItems: 'center',
  },
  input: {
    width: '100%',
    padding: '12px 14px',
    paddingRight: '80px',
    backgroundColor: 'rgba(15, 23, 42, 0.6)',
    border: '1px solid rgba(255, 255, 255, 0.1)',
    borderRadius: '10px',
    color: '#FFFFFF',
    fontSize: '14px',
    outline: 'none',
    boxSizing: 'border-box',
    transition: 'border-color 0.2s',
  },
  toggleBtn: {
    position: 'absolute',
    right: '12px',
    background: 'none',
    border: 'none',
    fontSize: '15px',
    cursor: 'pointer',
    opacity: 0.7,
  },
  copyBtn: {
    position: 'absolute',
    right: '40px',
    background: 'rgba(255, 255, 255, 0.08)',
    border: 'none',
    borderRadius: '6px',
    color: '#E5E7EB',
    padding: '3px 8px',
    fontSize: '11px',
    cursor: 'pointer',
  },
  submitBtn: {
    marginTop: '6px',
    backgroundColor: '#DC2626',
    backgroundImage: 'linear-gradient(135deg, #EF4444 0%, #B91C1C 100%)',
    color: '#FFFFFF',
    border: 'none',
    borderRadius: '10px',
    padding: '13px 20px',
    fontSize: '14px',
    fontWeight: 600,
    cursor: 'pointer',
    boxShadow: '0 4px 14px rgba(220, 38, 38, 0.4)',
    transition: 'opacity 0.2s, transform 0.1s',
  },
  submitBtnDisabled: {
    marginTop: '6px',
    backgroundColor: '#4B5563',
    color: '#9CA3AF',
    border: 'none',
    borderRadius: '10px',
    padding: '13px 20px',
    fontSize: '14px',
    fontWeight: 600,
    cursor: 'not-allowed',
  },
  footer: {
    marginTop: '24px',
    paddingTop: '16px',
    borderTop: '1px solid rgba(255, 255, 255, 0.06)',
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
  },
  footerItem: {
    display: 'flex',
    alignItems: 'flex-start',
    gap: '8px',
    fontSize: '11px',
    color: '#9CA3AF',
    lineHeight: 1.4,
  },
};
