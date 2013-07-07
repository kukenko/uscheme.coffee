# via http://rosettacode.org/wiki/Count_occurrences_of_a_substring#CoffeeScript
countSubstring = (str, substr) ->
  n = 0
  i = 0
  while (pos = str.indexOf(substr, i)) != -1
    n += 1
    i = pos + substr.length
  n

# repl (^_^)/

nodeREPL = require 'repl'
uscheme = require("./uscheme")

u = new uscheme.UScheme
g = [u.primitive_fun_env, u.boolean_env, u.list_env]

replDefaults =
  prompt: 'uscheme> '
  eval: (input, context, filename, cb) ->
    input = input.replace /\uFF00/g, '\n'
    input = input.replace /^\(([\s\S]*)\n\)$/m, '$1'
    ret = uscheme.UScheme._eval uscheme.UScheme.parse(input), g
    cb ret

addMultilineHandler = (repl) ->
  {rli, inputStream, outputStream} = repl

  multiline =
    initialPrompt: repl.prompt.replace /^[^> ]*/, (x) -> x.replace /./g, '-'
    prompt: repl.prompt.replace /^[^> ]*>?/, (x) -> x.replace /./g, '.'
    buffer: ''

  nodeLineListener = rli.listeners('line')[0]
  rli.removeListener 'line', nodeLineListener
  rli.on 'line', (cmd) ->
    unless cmd.match /^\s*$/
      multiline.buffer += "#{cmd}\n"

    if countSubstring(multiline.buffer, '(') > countSubstring(multiline.buffer, ')')
      rli.setPrompt multiline.prompt
      rli.prompt true
    else
      multiline.buffer = multiline.buffer.replace /\n/g, '\uFF00'
      nodeLineListener multiline.buffer
      multiline.buffer = ''

repl = nodeREPL.start replDefaults
repl.on 'exit', -> repl.outputStream.write '\n'
addMultilineHandler repl
repl
