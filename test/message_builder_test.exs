defmodule LoggerSyslogBackend.MessageBuilderTest do
  use ExUnit.Case
  doctest LoggerSyslogBackend.MessageBuilder

  @timestamp  {{2015,10,1}, {12,44,1}}
  @meta       [application: :upptec_slack_robot, module: UpptecSlack.SlackBot, function: "handle_cast/2", line: 1]

  test "will create a correct syslog message" do
    application = Dict.get(@meta, :application, nil)
    procid = Dict.get(@meta, :module, nil)
    message = LoggerSyslogBackend.MessageBuilder.build(:error, application, @timestamp, procid, "Hello PaperTrail!")
    # LoggerSyslogBackend.Sender.send("logs.papertrailapp.com",26405, message)
    assert "<11>Oct  1 12:44:01 upptec_slack_robot Elixir.UpptecSlack.SlackBot Hello PaperTrail!" == message
  end

end
