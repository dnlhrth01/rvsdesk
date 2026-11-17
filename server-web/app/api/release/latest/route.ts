import { NextResponse } from 'next/server';

// Official Release Metadata API
// Exposes verifiable release specifications, hashes, and audit statuses.

export async function GET() {
  const releaseData = {
    publisher: "RithV Services",
    product: "RVDesk",
    product_description: "Official RITHV Services Remote Desktop",
    version: "1.9.2",
    platform: "Windows x64 (10 / 11)",
    filename: "RVDesk.exe",
    file_size: 25815040,
    file_size_mb: 24.62,
    sha256: "44A3FD06E488379F9494F806A64F7D26E417056405F4C926DF5204CFC3E8C388",
    signature_status: "Unsigned",
    signature_details: "Executable contains no Authenticode digital signature.",
    is_signed: false,
    defender_scan_status: "Passed (No Threats Detected)",
    virustotal_status: "Manual Verification Available",
    virustotal_url: "https://www.virustotal.com/gui/file/44A3FD06E488379F9494F806A64F7D26E417056405F4C926DF5204CFC3E8C388",
    release_date: "2026-11-17T03:17:47Z",
    official_download: "https://rithvservices.my.id/downloads",
    direct_download_url: "https://rithvservices.my.id/api/download/rvsdesk",
    github_release_url: "https://github.com/dnlhrth01/rvsdesk/releases/tag/v1.9.2"
  };

  return NextResponse.json(releaseData, {
    status: 200,
    headers: {
      'Cache-Control': 'public, max-age=600, stale-while-revalidate=3600',
      'Access-Control-Allow-Origin': '*',
    },
  });
}

