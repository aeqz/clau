/** Encrypt arbitrary `data` by using a `password`.
 *
 * The first byte of the returned data corresponds to the encryption version number, and the
 * remaining ones depend on it.
 *
 * **Version 1**: the data is serialized to a UTF-8 JSON string and encrypted by using AES-GCM,
 * with the key being derived via PBKDF2. The first 16 bytes after the version number correspond
 * to the algorythm IV, the next 16 to the key salt and the remaining bytes to the cyphertext.
 */
export const encrypt =
  (password: string) =>
  async (data: unknown): Promise<ArrayBuffer[]> => {
    // Version number
    const versionBuffer = new Uint8Array([1]).buffer

    // Algorithm parameters
    const ivBuffer = window.crypto.getRandomValues(new Uint8Array(16)).buffer
    const algorithm = {
      name: 'AES-GCM',
      iv: ivBuffer,
    }

    // Derive key from password
    const saltBuffer = window.crypto.getRandomValues(new Uint8Array(16)).buffer
    const encryptKey = await window.crypto.subtle.importKey(
      'raw',
      await deriveKey(password, saltBuffer),
      algorithm,
      false,
      ['encrypt'],
    )

    // Encrypt data as UTF-8 JSON string
    const cyphertextBuffer = await window.crypto.subtle.encrypt(
      algorithm,
      encryptKey,
      new TextEncoder().encode(JSON.stringify(data)),
    )

    return [versionBuffer, ivBuffer, saltBuffer, cyphertextBuffer]
  }

/** Decrypt `data` that has been encoded by using the `encrypt` function with the given `password`.
 *
 * Returns `null` if the decryption fails because of the password being wrong or the plaintext
 * data being invalid.
 */
export const decrypt =
  (password: string) =>
  async (data: ArrayBuffer): Promise<unknown | null> => {
    // Version number
    const schemaVersion = new Uint8Array(data, 0, 1)[0]
    if (schemaVersion !== 1) {
      throw new Error(`Unknown schema version ${schemaVersion}`)
    }

    // Algorithm parameters
    const algorithm = {
      name: 'AES-GCM',
      iv: data.slice(1, 17),
    }

    // Derive key from password
    const decryptKey = await window.crypto.subtle.importKey(
      'raw',
      await deriveKey(password, data.slice(17, 33)),
      algorithm,
      false,
      ['decrypt'],
    )

    try {
      // Decrypt content
      const plaintextBuffer = await window.crypto.subtle.decrypt(
        algorithm,
        decryptKey,
        data.slice(33),
      )

      // Parse as UTF-8 JSON string
      return JSON.parse(new TextDecoder('utf-8').decode(plaintextBuffer))
    } catch (e) {
      if (e instanceof TypeError) return null
      if (e instanceof SyntaxError) return null
      if (e instanceof Error && e.name === 'OperationError') return null
      throw e
    }
  }

const deriveKey = async (
  password: string,
  salt: ArrayBuffer,
): Promise<ArrayBuffer> =>
  window.crypto.subtle.deriveBits(
    {
      name: 'PBKDF2',
      hash: 'SHA-256',
      salt,
      iterations: 600_000,
    },
    await window.crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(password),
      'PBKDF2',
      false,
      ['deriveBits'],
    ),
    16 * 8,
  )
