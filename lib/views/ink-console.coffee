{CompositeDisposable, Range, Point, Emitter} = require 'atom'
Highlights = require 'highlights'
CONSOLE_URI = 'atom://proto-repl/console'

# TODOs
## - executed code should not be printed with "ns => <result>"
## - clear repl doesn't work.

## - enter in code entry area gets exception
# Caused by lisp paredit. We need to disable that in the Atom ink console.

## - Need to tweak some info and stdout calls. Stdout should go to real stdout
# info type stuff explicitly from proto repl should be info


module.exports =

# TODO comment this
class InkConsole
  emitter: null
  subscriptions: null
  ink: null
  console: null
  higlighter: null

  constructor: (@ink)->
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    # Register console opener
    @subscriptions.add(atom.workspace.addOpener((uri) =>
      if (uri == CONSOLE_URI)
        console.log("Console open")
        @emitter.emit 'proto-repl-ink-console:open'
        return @console
    ))
    @startConsole()
    @highlighter = new Highlights(registry: atom.grammars)

  startConsole: () ->
    # create the console object
    @console = @ink.Console.fromId('proto-repl')
    # overwrite ink's Console title
    TAB_TITLE = 'Proto-REPL'
    @console.getTitle = () -> TAB_TITLE
    @console.emitter.emit('did-change-title', TAB_TITLE)
    # activate and open the console
    @console.activate()
    @console.onEval (ed) => @executeEnteredText ed
    # set console modes
    @console.setModes([
      {name: 'proto-repl', default: true, grammar: 'source.clojure'}
    ])
    atom.workspace.open(CONSOLE_URI,
      {
        split: 'right',
        searchAllPanes: true
      })

  # TODO this may not be needed or make sense the current way. The console is already open
  # Calls the callback after the text editor has been opened.
  onDidOpen: (callback)->
    # Already open
    callback()

  # Calls the callback after the text editor window has been closed.
  onDidClose: (callback)->
    #TODO figure out how to detect close happened and to emit it.
    @emitter.on 'proto-repl-ink-console:close', callback

  # Clears all output and text entry in the REPL.
  clear: ->
    @console.reset()

  # TODO add comments for these methods

  info: (text)->
    @console.info(text)

  stderr: (text)->
    @console.stderr(text)

  stdout: (text)->
    @console.stdout(text)

  result: (text)->
    html = @highlighter.highlightSync
      fileContents: text
      scopeName: 'source.clojure'

    div = document.createElement('div')
    div.innerHTML = html
    el = div.firstChild
    el.classList.add("proto-repl-console")

    @console.result(el, {error: false})

  displayExecutedCode: (code)->
    inputCell = @console.getInput()
    if not (inputCell.editor.getText())
      inputCell.editor.setText(code)
    @console.logInput() #history
    @console.done()
    @console.input()

  # Executes the text that was entered in the entry area
  executeEnteredText: (inputCell={}) ->
    editor = @console.getInput().editor
    return null unless editor.getText().trim()
    code = editor.getText()
    # Wrap code in do block so that multiple statements entered at the REPL
    # will execute all of them
    protoRepl.executeCode("(do #{code})", displayCode: code)
