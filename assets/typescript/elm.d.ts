declare module '*.elm' {
  export const Elm: {
    Main: ElmMain<{
      save: PortFromElm<{
        name: string
        data: unknown
        password: string
      }>
      saved: PortToElm<boolean>
      draggingFile: PortToElm<boolean>
      fileDropped: PortToElm<string | null>
      loadDropped: PortFromElm<{
        password: string
      }>
      loadFromInput: PortFromElm<{
        inputId: string
        password: string
      }>
      loaded: PortToElm<unknown | null>
    }>
  }
}
