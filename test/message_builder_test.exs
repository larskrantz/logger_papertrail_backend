defmodule LoggerPapertrailBackend.MessageBuilderTest do
  use ExUnit.Case
  doctest LoggerPapertrailBackend.MessageBuilder

  @timestamp  {{2015,10,1}, {12,44,1}}
  @meta       [application: :upptec_slack_robot, module: UpptecSlack.SlackBot, function: "handle_cast/2", line: 1]

  test "will create a correct syslog message" do
    application = Keyword.get(@meta, :application, nil)
    procid = Keyword.get(@meta, :module, nil)
    message = LoggerPapertrailBackend.MessageBuilder.build("Hello PaperTrail!", :error, application, @timestamp, procid)
    assert "<11>Oct  1 12:44:01 upptec_slack_robot Elixir.UpptecSlack.SlackBot Hello PaperTrail!" == message
  end

end
