import { Elm } from '../../src/Main.elm'

import * as Literals from './literals'

Elm.Main.init({
  flags: {
    literals: Literals.forCurrentLocale,
  },
})
