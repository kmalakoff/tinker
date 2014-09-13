module.exports = class CommanderUtils
  @getOptionsOwner: (program, command_name) ->
    return command for command in program.commands when command._name is command_name
    return null

  @extractCommandOptions: (program) -> CommanderUtils.extractOptions(program, program.args[program.args.length-1]._name)
  @extractOptions: (program, command_name) ->
    program = CommanderUtils.getOptionsOwner(program, command_name) if command_name
    (console.log "Couldn't find options for #{command_name}"; return {}) unless program

    options = if program.parent then CommanderUtils.extractOptions(program.parent) else {}
    for option_info in program.options when program.hasOwnProperty(key = option_info.long.replace('--', ''))
      options[key] = program[key]
    return options
