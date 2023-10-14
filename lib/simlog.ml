module Filter = Filter
module Formatter = Formatter
module Recorder = Recorder
module Printer = Printer

module type Logger = sig
  module Filter : Filter.T
  module Printer : Printer.T
  module Formatter : Formatter.T
  module Recorder : Recorder.T
end

module Builtin = struct
  module Logger : Logger = struct
    include Filter.Builtin
    include Formatter.Builtin
    include Recorder.Builtin
    module Printer = Printer.Builtin.Stdout_Mutex_Printer
  end
end

module Make (M : Logger) = struct
  let[@inline always] __record ~(level : Recorder.Level.t) ~(str : string) :
      unit =
    Recorder.record ~opt:M.Recorder.opt ~level str
    |> M.Filter.filter
    |> Option.iter (fun record ->
           M.Formatter.format record M.Printer.config.target |> M.Printer.print)

  let[@inline always] info (fmt : 'a) =
    Format.ksprintf (fun str -> __record ~str ~level:Recorder.Level.Info) fmt

  let[@inline always] error (fmt : 'a) =
    Format.ksprintf (fun str -> __record ~str ~level:Recorder.Level.Error) fmt

  let[@inline always] warn (fmt : 'a) =
    Format.ksprintf (fun str -> __record ~str ~level:Recorder.Level.Warn) fmt

  let[@inline always] debug (fmt : 'a) =
    Format.ksprintf (fun str -> __record ~str ~level:Recorder.Level.Debug) fmt
end
