import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';

// Tetapan Lalai
const DEFAULT_SALT = 'rvs_auth_sec_2026';
const DEFAULT_HASH = '741778e002a66a23da72acb792171d2127ff4395c248456dcb314904c6a26a6b'; // kata laluan: admin
const ADMIN_PIN = process.env.RVS_ADMIN_PIN || 'rvsadmin2026';

// Fail simpanan tempatan di folder public atau /tmp
function getAuthFilePath(): string {
  const publicPath = path.join(process.cwd(), 'public', 'rvsdesk-auth.json');
  return publicPath;
}

function readCurrentAuth(): { secret_hash: string; salt: string; version: number; updated_at: string } {
  try {
    const filePath = getAuthFilePath();
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf-8');
      const data = JSON.parse(content);
      return {
        secret_hash: data.secret_hash || DEFAULT_HASH,
        salt: data.salt || DEFAULT_SALT,
        version: data.version || 1,
        updated_at: data.updated_at || new Date().toISOString(),
      };
    }
  } catch (err) {
    console.warn('[RVSDesk Auth] Tidak dapat membaca fail fizikal, menggunakan memori/env:', err);
  }

  return {
    secret_hash: process.env.RVS_SECRET_HASH || DEFAULT_HASH,
    salt: process.env.RVS_SECRET_SALT || DEFAULT_SALT,
    version: 1,
    updated_at: new Date().toISOString(),
  };
}

// GET: Dipanggil oleh aplikasi RVSDesk.exe untuk menyemak hash terkini
export async function GET() {
  const authData = readCurrentAuth();

  return NextResponse.json(
    {
      app_name: 'RVSDesk',
      endpoint: 'https://service.danialharith.space/rvsdesk-auth.json',
      secret_hash: authData.secret_hash,
      salt: authData.salt,
      version: authData.version,
      updated_at: authData.updated_at,
    },
    {
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
        'Access-Control-Allow-Origin': '*',
      },
    }
  );
}

// POST: Digunakan oleh halaman Admin untuk menukar kata laluan serta-merta
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { adminPin, newPassword, salt = DEFAULT_SALT } = body;

    // 1. Verify Admin PIN for security
    if (!adminPin || adminPin !== ADMIN_PIN) {
      return NextResponse.json(
        { success: false, error: 'Invalid Admin PIN! Access denied.' },
        { status: 401 }
      );
    }

    // 2. Validate new password
    if (!newPassword || typeof newPassword !== 'string' || newPassword.trim().length === 0) {
      return NextResponse.json(
        { success: false, error: 'New password cannot be empty!' },
        { status: 400 }
      );
    }

    const currentAuth = readCurrentAuth();
    const newVersion = (currentAuth.version || 1) + 1;
    const updatedAt = new Date().toISOString();

    // 3. Compute Salted SHA-256 Hash
    const secretHash = crypto
      .createHash('sha256')
      .update(salt + newPassword.trim())
      .digest('hex');

    const newAuthPayload = {
      app_name: 'RVSDesk',
      endpoint: 'https://service.danialharith.space/rvsdesk-auth.json',
      secret_hash: secretHash,
      salt: salt,
      version: newVersion,
      updated_at: updatedAt,
    };

    // 4. Save to public/rvsdesk-auth.json if filesystem permits
    try {
      const filePath = getAuthFilePath();
      const dirPath = path.dirname(filePath);
      if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
      }
      fs.writeFileSync(filePath, JSON.stringify(newAuthPayload, null, 2), 'utf-8');
    } catch (fsErr) {
      console.warn('[RVSDesk Auth] Warning: Failed writing to public/, may be read-only environment:', fsErr);
    }

    return NextResponse.json(
      {
        success: true,
        message: 'RVSDesk controller secret password updated successfully!',
        secret_hash: secretHash,
        salt: salt,
        version: newVersion,
        updated_at: updatedAt,
      },
      {
        headers: {
          'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || 'Internal server error processing request.' },
      { status: 500 }
    );
  }
}
