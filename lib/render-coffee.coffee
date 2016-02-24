coffee = require 'coffee-script'
vm     = require 'vm'

module.exports =

  eval: (code) ->
    try
      output = vm.runInThisContext(coffee.compile(code, bare: true))
      console.log "Output COFFEE"
      console.log output
    catch e
      output = "Error:#{e}"
      console.error "Eval Error:", e

    output