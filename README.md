# Clau

A minimalistic password store or, as a friend properly pointed out, just an encrypted CRUD. The encryption mechanism is explained in [this module](./assets/typescript/crypto.ts) comments.

> [!IMPORTANT]
> This is a pet project. Use it at your own risk.

A demo is available [here](https://aeqz.github.io/clau/).

## Development

Requires `Node.js` to be installed. Then:

```sh
# Install dependencies
npm i

# Run development server with debugger and hot reload
npm run dev

# Generate static assets in the dist directory
npm run build
```

## Improvements or extensions

These are some missing features or possible improvements that could be added:

- Undo/redo edits.
- Filtering and ordering.
- Copy/paste field contents.
- Password generator.
- Warn about unsaved changes.
- Save in local storage.

The UI could be improved too.
