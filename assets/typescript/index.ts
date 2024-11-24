import { Elm } from '../../src/Main.elm'

import * as Crypto from './crypto'
import * as File from './file'
import * as Literals from './literals'

const app = Elm.Main.init({
  flags: {
    literals: Literals.forCurrentLocale(),
  },
})

app.ports.save.subscribe(({ name, data, password }) =>
  Crypto.encrypt(password)(data)
    .then(File.download(name))
    .then(() => app.ports.saved.send(true))
    .catch(() => app.ports.saved.send(false)),
)

app.ports.loadFromInput.subscribe(({ inputId, password }) =>
  File.load(inputId)
    .then(Crypto.decrypt(password))
    .then(app.ports.loaded.send)
    .catch(app.ports.loaded.send),
)

File.onDrag(app.ports.draggingFile.send)

File.onDrop(file => app.ports.fileDropped.send(file?.name ?? null))

File.lastDropped(ref =>
  app.ports.loadDropped.subscribe(({ password }) => {
    if (!ref.file) {
      app.ports.loaded.send(null)
      return
    }

    ref.file
      .arrayBuffer()
      .then(Crypto.decrypt(password))
      .then(app.ports.loaded.send)
      .catch(app.ports.loaded.send)
  }),
)
