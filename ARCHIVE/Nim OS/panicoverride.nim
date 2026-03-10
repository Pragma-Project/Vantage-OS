# panicoverride.nim - Panic handler for freestanding kernel

{.push stack_trace: off, profiler: off.}

proc rawoutput(s: cstring) =
  # Can't output anything in freestanding mode
  discard

proc panic(s: cstring) {.noreturn.} =
  # Halt the CPU
  while true:
    asm """
      cli
      hlt
    """

{.pop.}
