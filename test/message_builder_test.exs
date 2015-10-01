defmodule LoggerSyslogBackend.MessageBuilderTest do
  use ExUnit.Case

  @timestamp  {{2015,10,1}, {12,44,1}}
  @meta       [application: :upptec_slack_robot, module: UpptecSlack.SlackBot, function: "handle_cast/2", line: 1]

  test "will create a correct syslog message" do
    message = LoggerSyslogBackend.MessageBuilder.build(:error, :user, "hostname.ignore.me", @timestamp, "Hello syslogd!", @meta)
    #LoggerSyslogBackend.Sender.send("logs.papertrailapp.com",26405,message)
    assert "<11>Oct  1 12:44:01 hostname.ignore.me Elixir.UpptecSlack.SlackBot Hello syslogd!" == message
  end

end
