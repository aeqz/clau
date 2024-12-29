import ca from '../literals/ca.json'
import en from '../literals/en.json'
import es from '../literals/es.json'

export type Literals = typeof ca

/** Returns literals corresponding to the browser preferred language.
 *
 * It also checks that all locale literals have the same type.
 */
export const forCurrentLocale = (): Literals => {
  // This could be changed to dynamically import the one corresponding to the current locale, but
  // that would produce an additional fetch that doesn't seem to worth it right now.
  switch (navigator.language.split('-')[0]) {
    case 'ca':
      return ca
    case 'es':
      return es
    default:
      return en
  }
}
