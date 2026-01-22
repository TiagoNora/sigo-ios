/**
 * AES-256-GCM Encryption Utility for Onecare Web Frontend
 *
 * Fetches encryption key from Firestore and encrypts tenant config for QR codes.
 * The mobile app uses the same key from Firestore to decrypt.
 *
 * ## Setup
 * 1. Add encryption key to Firestore: config/encryption { qr_key: "..." }
 * 2. Use this utility to encrypt tenant configs for QR codes
 *
 * ## Usage
 * ```typescript
 * const encryptionService = new QREncryptionService();
 *
 * const encrypted = await encryptionService.encryptTenantConfig({
 *   tenantId: 'acme-corp',
 *   apiUrl: 'https://api.acme.com',
 *   authUrl: 'https://auth.acme.com',
 *   clientId: 'mobile-app-client',
 * });
 *
 * // Use 'encrypted' string to generate QR code
 * ```
 */

import { doc, getDoc, Firestore } from 'firebase/firestore';

// ============================================
// Types
// ============================================

export interface TenantConfig {
  tenantId: string;
  apiUrl: string;
  authUrl?: string;
  clientId?: string;
  clientSecret?: string;
  additionalConfig?: Record<string, unknown>;
}

// ============================================
// QR Encryption Service
// ============================================

export class QREncryptionService {
  private firestore: Firestore;
  private cachedKey: string | null = null;

  // Firestore paths - must match mobile app
  private static readonly CONFIG_COLLECTION = 'config';
  private static readonly ENCRYPTION_DOCUMENT = 'encryption';
  private static readonly KEY_FIELD = 'qr_key';

  constructor(firestore: Firestore) {
    this.firestore = firestore;
  }

  /**
   * Fetches encryption key from Firestore (caches in memory).
   */
  async getEncryptionKey(): Promise<string> {
    if (this.cachedKey) {
      return this.cachedKey;
    }

    const docRef = doc(
      this.firestore,
      QREncryptionService.CONFIG_COLLECTION,
      QREncryptionService.ENCRYPTION_DOCUMENT
    );

    const docSnap = await getDoc(docRef);

    if (!docSnap.exists()) {
      throw new Error('Encryption config not found in Firestore');
    }

    const key = docSnap.data()?.[QREncryptionService.KEY_FIELD];

    if (!key || typeof key !== 'string') {
      throw new Error('Encryption key not found in Firestore document');
    }

    this.cachedKey = key;
    return key;
  }

  /**
   * Encrypts tenant configuration for QR code.
   *
   * @param config - The tenant configuration to encrypt
   * @returns Base64 encoded encrypted data (for QR code)
   */
  async encryptTenantConfig(config: TenantConfig): Promise<string> {
    const secretKey = await this.getEncryptionKey();
    return this.encrypt(JSON.stringify(config), secretKey);
  }

  /**
   * Decrypts tenant configuration (for testing/verification).
   *
   * @param encryptedBase64 - Base64 encoded encrypted data
   * @returns Decrypted tenant configuration
   */
  async decryptTenantConfig(encryptedBase64: string): Promise<TenantConfig> {
    const secretKey = await this.getEncryptionKey();
    const decrypted = await this.decrypt(encryptedBase64, secretKey);
    return JSON.parse(decrypted);
  }

  /**
   * Encrypts data using AES-256-GCM.
   * Output format: base64(iv[12] + ciphertext + authTag[16])
   */
  private async encrypt(plaintext: string, secretKey: string): Promise<string> {
    const encoder = new TextEncoder();
    const data = encoder.encode(plaintext);

    // Derive 256-bit key from secret using SHA-256
    const keyMaterial = await crypto.subtle.digest(
      'SHA-256',
      encoder.encode(secretKey)
    );

    const key = await crypto.subtle.importKey(
      'raw',
      keyMaterial,
      { name: 'AES-GCM' },
      false,
      ['encrypt']
    );

    // Generate random 12-byte IV
    const iv = crypto.getRandomValues(new Uint8Array(12));

    // Encrypt (result includes ciphertext + 16-byte auth tag)
    const encrypted = await crypto.subtle.encrypt(
      { name: 'AES-GCM', iv: iv },
      key,
      data
    );

    // Combine: iv + ciphertext + authTag
    const combined = new Uint8Array(iv.length + encrypted.byteLength);
    combined.set(iv);
    combined.set(new Uint8Array(encrypted), iv.length);

    // Convert to base64
    return btoa(String.fromCharCode(...combined));
  }

  /**
   * Decrypts data using AES-256-GCM.
   * Expected format: base64(iv[12] + ciphertext + authTag[16])
   */
  private async decrypt(encryptedBase64: string, secretKey: string): Promise<string> {
    const encoder = new TextEncoder();

    // Decode base64
    const combined = Uint8Array.from(atob(encryptedBase64), (c) =>
      c.charCodeAt(0)
    );

    // Extract IV (first 12 bytes)
    const iv = combined.slice(0, 12);

    // Extract ciphertext + authTag (rest)
    const ciphertextWithTag = combined.slice(12);

    // Derive 256-bit key from secret using SHA-256
    const keyMaterial = await crypto.subtle.digest(
      'SHA-256',
      encoder.encode(secretKey)
    );

    const key = await crypto.subtle.importKey(
      'raw',
      keyMaterial,
      { name: 'AES-GCM' },
      false,
      ['decrypt']
    );

    // Decrypt
    const decrypted = await crypto.subtle.decrypt(
      { name: 'AES-GCM', iv: iv },
      key,
      ciphertextWithTag
    );

    const decoder = new TextDecoder();
    return decoder.decode(decrypted);
  }

  /**
   * Clears the cached key (if key rotation is needed).
   */
  clearCache(): void {
    this.cachedKey = null;
  }
}

// ============================================
// Example Usage
// ============================================

/*
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

// Initialize Firebase
const firebaseConfig = {
  // Your Firebase config
};

const app = initializeApp(firebaseConfig);
const firestore = getFirestore(app);

// Create service
const qrEncryption = new QREncryptionService(firestore);

// Encrypt tenant config for QR code
async function generateQRCode() {
  const config: TenantConfig = {
    tenantId: 'acme-corp',
    apiUrl: 'https://api.acme-corp.com/v1',
    authUrl: 'https://auth.acme-corp.com/oauth',
    clientId: 'onecare-mobile-app',
  };

  const encrypted = await qrEncryption.encryptTenantConfig(config);
  console.log('QR Code Data:', encrypted);

  // Generate QR code with 'encrypted' string
  // e.g., using qrcode library: QRCode.toDataURL(encrypted)

  // Verify (optional)
  const decrypted = await qrEncryption.decryptTenantConfig(encrypted);
  console.log('Verified:', decrypted);
}

generateQRCode();
*/
