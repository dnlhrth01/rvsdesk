import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

// RITHV Services - Official RVDesk Binary Download Endpoint
// Serves the official single portable executable with cryptographic integrity headers.

const CURRENT_VERSION = '1.9.2';
const CURRENT_SHA256 = '44A3FD06E488379F9494F806A64F7D26E417056405F4C926DF5204CFC3E8C388';
const GITHUB_FALLBACK_URL = `https://github.com/dnlhrth01/rvsdesk/releases/download/v${CURRENT_VERSION}/RVDesk-Portable.exe`;

export async function GET() {
  try {
    // 1. Check local static storage in public/ or dist/
    const possiblePaths = [
      path.join(process.cwd(), 'public', 'RVDesk.exe'),
      path.join(process.cwd(), 'public', 'downloads', 'RVDesk.exe'),
      path.join(process.cwd(), 'RVDesk.exe'),
    ];

    for (const filePath of possiblePaths) {
      if (fs.existsSync(filePath)) {
        const stat = fs.statSync(filePath);
        const fileStream = fs.createReadStream(filePath);
        
        return new NextResponse(fileStream as any, {
          status: 200,
          headers: {
            'Content-Type': 'application/vnd.microsoft.portable-executable',
            'Content-Length': stat.size.toString(),
            'Content-Disposition': 'attachment; filename="RVDesk.exe"',
            'Cache-Control': 'public, max-age=3600, stale-while-revalidate=86400',
            'x-software-version': CURRENT_VERSION,
            'x-checksum-sha256': CURRENT_SHA256,
            'x-publisher': 'RITHV Services',
            'x-signature-status': 'Unsigned',
          },
        });
      }
    }

    // 2. If binary is hosted on GitHub Releases, redirect directly
    return NextResponse.redirect(GITHUB_FALLBACK_URL, {
      status: 302,
      headers: {
        'x-software-version': CURRENT_VERSION,
        'x-checksum-sha256': CURRENT_SHA256,
        'x-publisher': 'RITHV Services',
        'x-signature-status': 'Unsigned',
      },
    });
  } catch (error) {
    console.error('[Download API Error]', error);
    return NextResponse.redirect(GITHUB_FALLBACK_URL, 302);
  }
}

