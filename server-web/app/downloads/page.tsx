'use client';

import React, { useState } from 'react';

// RITHV Services - Official Software Downloads & Cryptographic Verification Portal
// Meets zero-cost, transparent, and non-misleading security guidelines.

interface ReleaseItem {
  version: string;
  releaseDate: string;
  filename: string;
  fileSize: string;
  sha256: string;
  signatureStatus: string;
  defenderStatus: string;
  vtUrl: string;
  changes: string[];
}

const HISTORICAL_RELEASES: ReleaseItem[] = [
  {
    version: '1.9.2',
    releaseDate: 'November 2026',
    filename: 'RVDesk.exe',
    fileSize: '24.62 MB',
    sha256: '44A3FD06E488379F9494F806A64F7D26E417056405F4C926DF5204CFC3E8C388',
    signatureStatus: 'Unsigned (Standard Open-Source)',
    defenderStatus: 'Clean (No Threats Detected)',
    vtUrl: 'https://www.virustotal.com/gui/file/44A3FD06E488379F9494F806A64F7D26E417056405F4C926DF5204CFC3E8C388',
    changes: [
      'In-App 1-Click Update System with automated repository release detection',
      'Modern Dark Obsidian and Crimson Red Figcraft UI redesign',
      '1-Click Copy ID & Password for simplified technician onboarding',
      'Strict English-only interface and zero generic emojis across all surfaces',
      'Windows Defender pre-distribution scan verified'
    ]
  },
  {
    version: '1.9.1',
    releaseDate: 'October 2026',
    filename: 'RVDesk.exe',
    fileSize: '24.58 MB',
    sha256: '843B2A183C9031E21B97204A2CE7E756B7A6C131E2D489C8BF1D7A76EDC65C74',
    signatureStatus: 'Unsigned (Standard Open-Source)',
    defenderStatus: 'Clean (No Threats Detected)',
    vtUrl: 'https://www.virustotal.com/gui/file/843B2A183C9031E21B97204A2CE7E756B7A6C131E2D489C8BF1D7A76EDC65C74',
    changes: [
      'Multi-tier fallback for release assets during CI/CD compilation',
      'Relay and rendezvous routing optimizations',
      'Updated authority documentation and offline verification helpers'
    ]
  },
  {
    version: '1.8.0',
    releaseDate: 'October 2026',
    filename: 'RVSDesk.exe',
    fileSize: '24.52 MB',
    sha256: '2DB88C48642EC6573827C5247FF43929B6C07E3B26355A47FED958FFE4E3CBF6',
    signatureStatus: 'Unsigned (Legacy Line)',
    defenderStatus: 'Clean (No Threats Detected)',
    vtUrl: 'https://www.virustotal.com/gui/file/2DB88C48642EC6573827C5247FF43929B6C07E3B26355A47FED958FFE4E3CBF6',
    changes: [
      'Rebrand from RVSDesk to RVDesk portable line',
      'Custom relay console integration',
      'PE VersionInfo metadata stamping'
    ]
  }
];

export default function DownloadsPage() {
  const latest = HISTORICAL_RELEASES[0];
  const [copiedHash, setCopiedHash] = useState(false);
  const [copiedCommand, setCopiedCommand] = useState(false);
  const [activeTab, setActiveTab] = useState<'powershell' | 'gui'>('powershell');

  const copyToClipboard = (text: string, isHash: boolean) => {
    navigator.clipboard.writeText(text);
    if (isHash) {
      setCopiedHash(true);
      setTimeout(() => setCopiedHash(false), 2000);
    } else {
      setCopiedCommand(true);
      setTimeout(() => setCopiedCommand(false), 2000);
    }
  };

  const psCommand = `(Get-FileHash .\\${latest.filename} -Algorithm SHA256).Hash -eq "${latest.sha256}"`;

  return (
    <div className="min-h-screen bg-[#070A0F] text-slate-100 font-sans selection:bg-[#DC2626] selection:text-white">
      {/* Top Notification Bar */}
      <div className="border-b border-slate-800/80 bg-[#0F172A]/70 backdrop-blur-md px-4 py-2.5 text-xs text-center text-slate-400">
        <span className="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold bg-[#1E293B] text-[#F87171] border border-[#334155] mr-2">
          INTEGRITY GUARANTEE
        </span>
        All RITHV Services binaries are cryptographically indexed with SHA-256 checksums and pre-scanned with Microsoft Defender.
      </div>

      <main className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-12">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#1E293B]/80 border border-slate-700 text-xs text-[#F87171] font-semibold mb-4">
            <span>OFFICIAL SOFTWARE DISTRIBUTION PORTAL</span>
          </div>
          <h1 className="text-3xl sm:text-5xl font-extrabold tracking-tight text-white mb-4">
            Download <span className="text-[#DC2626]">RVDesk</span> Portable
          </h1>
          <p className="text-base sm:text-lg text-slate-400 leading-relaxed">
            Fast, secure, standalone remote assistance software for RITHV Services clients and technicians.
            Single portable executable — zero installer, zero telemetry, and zero cost.
          </p>
        </div>

        {/* Primary Download Card */}
        <div className="bg-[#0F172A] border border-slate-800 rounded-2xl shadow-2xl overflow-hidden mb-12">
          <div className="p-6 sm:p-10 border-b border-slate-800/80 bg-gradient-to-b from-[#1E293B]/30 to-transparent">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
              <div>
                <div className="flex items-center gap-3 mb-2">
                  <h2 className="text-2xl font-bold text-white tracking-tight">RVDesk Portable</h2>
                  <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-[#DC2626]/20 text-[#F87171] border border-[#DC2626]/40">
                    v{latest.version} (Latest)
                  </span>
                  <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/30">
                    Windows x64
                  </span>
                </div>
                <p className="text-sm text-slate-400">
                  Target: <code className="text-slate-300 font-mono">{latest.filename}</code> • Size: {latest.fileSize} • Released: {latest.releaseDate}
                </p>
              </div>

              {/* Action Buttons */}
              <div className="flex flex-col sm:flex-row gap-3">
                <a
                  href="/api/download/rvsdesk"
                  className="inline-flex items-center justify-center px-6 py-3.5 rounded-xl text-sm font-bold bg-[#DC2626] hover:bg-[#B91C1C] text-white shadow-lg shadow-red-900/30 transition-all hover:scale-[1.02] active:scale-[0.98]"
                >
                  <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                  </svg>
                  Download Standalone (.exe)
                </a>
                <a
                  href="https://github.com/dnlhrth01/rvsdesk/releases/latest"
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex items-center justify-center px-5 py-3.5 rounded-xl text-sm font-semibold bg-[#1E293B] hover:bg-[#334155] text-slate-200 border border-slate-700 transition-all"
                >
                  GitHub Mirror
                </a>
              </div>
            </div>
          </div>

          {/* Cryptographic Hash Bar */}
          <div className="p-6 sm:p-8 bg-[#070A0F]/50">
            <div className="mb-3 flex items-center justify-between">
              <div className="text-xs font-bold uppercase tracking-wider text-[#F87171] flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                Official SHA-256 Cryptographic Checksum
              </div>
              <button
                onClick={() => copyToClipboard(latest.sha256, true)}
                className="text-xs font-semibold px-2.5 py-1 rounded bg-[#1E293B] hover:bg-[#334155] text-slate-200 border border-slate-700 transition-colors"
              >
                {copiedHash ? '[COPIED]' : 'COPY HASH'}
              </button>
            </div>
            <div className="bg-[#020617] border border-slate-800 rounded-xl p-4 font-mono text-xs sm:text-sm text-slate-200 break-all select-all flex items-center justify-between gap-4">
              <span>{latest.sha256}</span>
            </div>
            <p className="mt-2 text-xs text-slate-500">
              Compute the SHA-256 hash on your computer before executing to verify that the file is authentic and unaltered.
            </p>
          </div>

          {/* Security & Audit Breakdown */}
          <div className="grid grid-cols-1 sm:grid-cols-3 divide-y sm:divide-y-0 sm:divide-x divide-slate-800 border-t border-slate-800 bg-[#0F172A]">
            <div className="p-5">
              <div className="text-xs text-slate-500 font-semibold mb-1">Authenticode Digital Signature</div>
              <div className="text-sm font-bold text-amber-400 flex items-center gap-1.5">
                <span>{latest.signatureStatus}</span>
              </div>
              <p className="text-[11px] text-slate-500 mt-1">
                Zero-cost open source. No commercial certificate purchased.
              </p>
            </div>

            <div className="p-5">
              <div className="text-xs text-slate-500 font-semibold mb-1">Microsoft Defender Scan</div>
              <div className="text-sm font-bold text-emerald-400 flex items-center gap-1.5">
                <span>{latest.defenderStatus}</span>
              </div>
              <p className="text-[11px] text-slate-500 mt-1">
                Scanned locally via MpCmdRun.exe prior to distribution.
              </p>
            </div>

            <div className="p-5">
              <div className="text-xs text-slate-500 font-semibold mb-1">VirusTotal Multi-Engine Inspection</div>
              <a
                href={latest.vtUrl}
                target="_blank"
                rel="noreferrer"
                className="text-sm font-bold text-[#F87171] hover:underline flex items-center gap-1.5"
              >
                <span>View Public Report</span>
                <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                </svg>
              </a>
              <p className="text-[11px] text-slate-500 mt-1">
                Publicly inspectable across 70+ antivirus engines.
              </p>
            </div>
          </div>
        </div>

        {/* Verification Instructions Section */}
        <div className="bg-[#0F172A] border border-slate-800 rounded-2xl p-6 sm:p-8 mb-12">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-xl font-bold text-white">How to Verify File Integrity</h3>
              <p className="text-xs text-slate-400 mt-1">
                Confirm your download is 100% genuine using native Windows tools. No extra software needed.
              </p>
            </div>
            <div className="flex rounded-lg bg-[#070A0F] p-1 border border-slate-800">
              <button
                onClick={() => setActiveTab('powershell')}
                className={`px-3 py-1 text-xs font-semibold rounded-md transition-colors ${
                  activeTab === 'powershell' ? 'bg-[#DC2626] text-white' : 'text-slate-400 hover:text-white'
                }`}
              >
                PowerShell (Instant)
              </button>
              <button
                onClick={() => setActiveTab('gui')}
                className={`px-3 py-1 text-xs font-semibold rounded-md transition-colors ${
                  activeTab === 'gui' ? 'bg-[#DC2626] text-white' : 'text-slate-400 hover:text-white'
                }`}
              >
                1-Click Script
              </button>
            </div>
          </div>

          {activeTab === 'powershell' ? (
            <div>
              <p className="text-xs text-slate-300 mb-3">
                1. Open PowerShell in the folder where you downloaded <code className="text-[#F87171]">{latest.filename}</code>.
              </p>
              <p className="text-xs text-slate-300 mb-3">
                2. Run the following command. It will return <code className="text-emerald-400 font-bold">True</code> if your file is authentic:
              </p>
              <div className="relative bg-[#020617] border border-slate-800 rounded-xl p-4 font-mono text-xs text-slate-200">
                <code>{psCommand}</code>
                <button
                  onClick={() => copyToClipboard(psCommand, false)}
                  className="absolute right-3 top-3 text-[11px] font-semibold px-2 py-1 rounded bg-[#1E293B] hover:bg-[#334155] text-slate-300 border border-slate-700"
                >
                  {copiedCommand ? 'COPIED' : 'COPY COMMAND'}
                </button>
              </div>
            </div>
          ) : (
            <div>
              <p className="text-xs text-slate-300 mb-3">
                Download the official verification script bundled with every release:
              </p>
              <div className="bg-[#020617] border border-slate-800 rounded-xl p-4 text-xs space-y-2">
                <p className="text-slate-300">
                  • Place <code className="text-[#F87171]">Verify-RVDesk.ps1</code> in the same directory as <code className="text-[#F87171]">{latest.filename}</code>.
                </p>
                <p className="text-slate-300">
                  • Right-click and select <strong>Run with PowerShell</strong>.
                </p>
                <p className="text-slate-300">
                  • The script will calculate the hash, compare it against the official ledger, and output a detailed confirmation.
                </p>
              </div>
            </div>
          )}
        </div>

        {/* Transparency & Windows SmartScreen Notice */}
        <div className="bg-[#1E293B]/40 border border-slate-800 rounded-2xl p-6 sm:p-8 mb-12">
          <div className="flex items-start gap-4">
            <div className="w-10 h-10 rounded-xl bg-[#DC2626]/20 border border-[#DC2626]/40 flex items-center justify-center shrink-0 text-[#F87171]">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
            </div>
            <div>
              <h3 className="text-lg font-bold text-white mb-2">
                Transparency Notice: Windows SmartScreen &amp; &quot;Unknown Publisher&quot;
              </h3>
              <div className="text-xs text-slate-300 space-y-2 leading-relaxed">
                <p>
                  When launching RVDesk for the first time, Windows Defender SmartScreen may display:
                  <em className="text-amber-300 block my-1 font-sans bg-[#020617] p-2 rounded border border-slate-800">
                    &quot;Windows protected your PC — Microsoft Defender SmartScreen prevented an unrecognized app from starting.&quot;
                  </em>
                </p>
                <p>
                  <strong>Why does this occur?</strong> Microsoft SmartScreen flags newly released executables that lack commercial
                  EV code-signing certificates. Commercial certificates cost $400 to $900 annually, which contradicts our zero-cost
                  software model.
                </p>
                <p>
                  <strong>How to proceed safely:</strong> Always verify the SHA-256 hash using the instructions above. Once verified,
                  click <strong className="text-white">More info</strong> on the blue prompt, then click <strong className="text-white">Run anyway</strong>.
                </p>
                <p className="text-slate-500 italic">
                  Note: A matching SHA-256 checksum proves file integrity (that the binary is exactly as published by RITHV Services).
                  It does not claim that the executable is signed by Microsoft.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Release History & Version Ledger */}
        <div className="bg-[#0F172A] border border-slate-800 rounded-2xl p-6 sm:p-8">
          <h3 className="text-xl font-bold text-white mb-4">Cryptographic Release Ledger</h3>
          <p className="text-xs text-slate-400 mb-6">
            Permanent, verifiable historical record of published releases and their cryptographic fingerprints.
          </p>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-slate-800 text-slate-400 font-semibold">
                  <th className="py-3 px-4">Version</th>
                  <th className="py-3 px-4">Date</th>
                  <th className="py-3 px-4">Target File</th>
                  <th className="py-3 px-4">Size</th>
                  <th className="py-3 px-4">SHA-256 Checksum</th>
                  <th className="py-3 px-4">Signature</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60 font-mono">
                {HISTORICAL_RELEASES.map((item) => (
                  <tr key={item.version} className="hover:bg-[#1E293B]/30 transition-colors">
                    <td className="py-3.5 px-4 font-bold text-white font-sans">v{item.version}</td>
                    <td className="py-3.5 px-4 text-slate-400 font-sans">{item.releaseDate}</td>
                    <td className="py-3.5 px-4 text-slate-300">{item.filename}</td>
                    <td className="py-3.5 px-4 text-slate-400">{item.fileSize}</td>
                    <td className="py-3.5 px-4 text-[#F87171] break-all max-w-xs">{item.sha256}</td>
                    <td className="py-3.5 px-4 text-slate-400 font-sans">{item.signatureStatus}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Footer / Contact */}
        <div className="mt-12 text-center text-xs text-slate-500">
          <p>RITHV SERVICES © 2026 • Official Support &amp; Security Disclosure: <a href="mailto:rithvservices@gmail.com" className="text-[#F87171] hover:underline">rithvservices@gmail.com</a></p>
        </div>
      </main>
    </div>
  );
}

