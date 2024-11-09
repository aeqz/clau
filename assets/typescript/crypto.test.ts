import { expect, test } from 'vitest'

import * as Crypto from './crypto'

test('encrypts and decrypts simple data', async () => {
  const password = 'asdf'
  const data = { answer: 42 }

  const encrypted = await Crypto.encrypt(password)(data)
  const encryptedBuffer = await new Blob(encrypted).arrayBuffer()
  const decrypted = await Crypto.decrypt(password)(encryptedBuffer)

  expect(data).toEqual(decrypted)
})

test('using an empty password', async () => {
  const password = ''
  const data = { answer: 42 }

  const encrypted = await Crypto.encrypt(password)(data)
  const encryptedBuffer = await new Blob(encrypted).arrayBuffer()
  const decrypted = await Crypto.decrypt(password)(encryptedBuffer)

  expect(data).toEqual(decrypted)
})

test('decrypt fails if password is wrong', async () => {
  const encrypted = await Crypto.encrypt('asdf')({ answer: 42 })
  const encryptedBuffer = await new Blob(encrypted).arrayBuffer()

  const decrypted = await Crypto.decrypt('asdg')(encryptedBuffer)

  expect(decrypted).toBeNull
})

test('version 1 file snapshot', async () => {
  const response = await fetch(
    'data:application/octet-stream;base64,AXQIidnrWlV376OT1bbX1Co4gRMNOLfF5Ld+bKxuMhQritpMnGWo5Qilq/5cI+L+rqYdlQcgExe9/V0QpDblGM1O++lbo86i5H5A',
  )

  const encryptedBuffer = await response.arrayBuffer()
  const decrypted = await Crypto.decrypt('asdf')(encryptedBuffer)

  expect({
    keys: [],
    version: 'V1',
  }).toEqual(decrypted)
})
