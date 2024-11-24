/** Download some `data` as a binary file with the given `name`.
 *
 * Implemented by using an `<a>` HTML tag while the File System API is not widely supported.
 */
export const download =
  (name: string) =>
  async (data: ArrayBuffer[]): Promise<void> => {
    const reader = Object.assign(new FileReader(), {
      onload: () => {
        if (typeof reader.result !== 'string')
          throw new Error('Unexpected reader result')

        const element = document.createElement('a')
        element.setAttribute('href', reader.result)
        element.setAttribute('download', name)
        element.click()
      },
    })

    reader.readAsDataURL(
      new File(data, '', { type: 'application/octet-stream' }),
    )
  }

/** Load a file contents, selected via the `inputId` DOM node, as binary data.
 *
 * Implemented by using an `<input>` HTML tag while the File System API is not widely supported.
 */
export const load = async (inputId: string): Promise<ArrayBuffer> => {
  const inputField = document.getElementById(inputId)
  if (!(inputField !== null && inputField instanceof HTMLInputElement))
    throw new Error(`Input field ${inputId} not found`)

  const file = inputField.files?.item(0)
  if (!file) throw new Error('No file selected')

  return file.arrayBuffer()
}

/** Listen for files being dragged in the page. */
export const onDrag = (subscriber: (isDragging: boolean) => void) => {
  document.addEventListener('dragenter', event => {
    if (event.dataTransfer?.types[0] !== 'Files') return
    subscriber(true)
  })

  document.addEventListener('dragleave', event => {
    if (event.dataTransfer?.types[0] !== 'Files') return
    subscriber(false)
  })

  document.addEventListener('drop', event => {
    if (event.dataTransfer?.types[0] !== 'Files') return
    subscriber(false)
  })
}

/** Listen for files being dropped in the page. */
export const onDrop = (dropped: (file: File | undefined) => void) => {
  document.addEventListener('dragover', event => {
    if (event.dataTransfer?.types[0] !== 'Files') return
    event.preventDefault()
  })

  document.addEventListener('drop', event => {
    if (event.dataTransfer?.types[0] !== 'Files') return
    event.preventDefault()
    dropped(
      event.dataTransfer?.items[0]?.getAsFile() ?? event.dataTransfer?.files[0],
    )
  })
}

/** Provide a reference to the last dropped file. */
export const lastDropped = (
  withRef: (ref: { file: File | undefined }) => void,
) => {
  const ref: { file: File | undefined } = { file: undefined }
  onDrop(file => (ref.file = file))
  withRef(ref)
}
