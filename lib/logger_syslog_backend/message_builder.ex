defmodule LoggerSyslogBackend.MessageBuilder do
  @doc """
    Will build a syslog-message

  """
  def build(level, facility, hostname, timestamp, message, metadata) do
    application = Dict.get(metadata, :application, nil)
    procid = Dict.get(metadata, :module, nil)
    priority = calculate_priority(facility, level)
    bsd_timestamp = create_bsd_timestamp(timestamp)
    "<#{priority}>#{bsd_timestamp} #{hostname} #{procid} #{message}"
  end

  # assuming logger logs in local timestamp atm
  defp create_bsd_timestamp({{_y,mo,d},{h,m,s}}) do
    months = ~W{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec}
    padded_day = d |> Integer.to_string |> String.rjust(2)
    month = months |> Enum.at(mo-1)
    zeropad = fn(i) -> i |> Integer.to_string |> String.rjust(2, ?0) end
    "#{month} #{padded_day} #{zeropad.(h)}:#{zeropad.(m)}:#{zeropad.(s)}"
  end

  # https://tools.ietf.org/html/rfc5424#section-6.2.1
  defp calculate_priority(facility, level), do: facility(facility) * 8 + level(level)
  # Thanks to https://github.com/jkvor/erlang_syslog/blob/master/src/syslog.erl

  defp level(:emergency), do: 0 # system is unusable
  defp level(:alert), do: 1 # action must be taken immediately
  defp level(:critical), do: 2 # critical conditions
  defp level(:error), do: 3 # error conditions
  defp level(:warning), do: 4 # warning conditions
  defp level(:notice), do: 5 # normal but significant condition
  defp level(:info), do: 6 # informational
  defp level(:debug), do: 7 # debug-level messages
  defp level(_), do: level(:info) # default to info

  # % paraphrased from https://github.com/ngerakines/syslognif/blob/master/src/syslog.erl#L55
  defp facility(:kern), do: 0      # kernel messages
  defp facility(:user), do: 1      # random user-level messages
  defp facility(:mail), do: 2      # mail system
  defp facility(:daemon), do: 3    # system daemons
  defp facility(:auth), do: 4      # security/authorization messages
  defp facility(:syslog), do: 5    # messages generated internally by syslogd
  defp facility(:lpr), do: 6       # line printer subsystem
  defp facility(:news), do: 7      # network news subsystem
  defp facility(:uucp), do: 8      # UUCP subsystem
  defp facility(:cron), do: 9      # clock daemon
  defp facility(:authpriv), do: 10 # security/authorization messages (private)
  defp facility(:ftp), do: 11      # ftp daemon

  defp facility(:local0), do: 16   # reserved for local use
  defp facility(:local1), do: 17   # reserved for local use
  defp facility(:local2), do: 18   # reserved for local use
  defp facility(:local3), do: 19   # reserved for local use
  defp facility(:local4), do: 20   # reserved for local use
  defp facility(:local5), do: 21   # reserved for local use
  defp facility(:local6), do: 22   # reserved for local use
  defp facility(:local7), do: 23   # reserved for local use
  defp facility(_), do: facility(:user)
end
