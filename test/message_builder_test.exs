defmodule LoggerPapertrailBackend.MessageBuilderTest do
  use ExUnit.Case
  doctest LoggerPapertrailBackend.MessageBuilder

  @timestamp  {{2015,10,1}, {12,44,1}}
  @meta       [application: :upptec_slack_robot, module: UpptecSlack.SlackBot, function: "handle_cast/2", line: 1]

  test "will create a correct syslog message" do
    procid = Keyword.get(@meta, :module, nil)
    message = build_message(application(), procid)
    assert "<11>Oct  1 12:44:01 upptec_slack_robot UpptecSlack.SlackBot Hello PaperTrail!" == message
  end

  test "will trim to long tags so it is still informational" do
    procid = "LoggerPapertrailBackend.MessageBuilder.Sub.VeryLongModuleName"
    message = build_message(application(), procid)
    assert "<11>Oct  1 12:44:01 upptec_slack_robot Sub.VeryLongModuleName Hello PaperTrail!" == message
  end

  test "in extrem cases, will only have last module name and trim it" do
    procid = "ABCDEFGHIJKL.MNOPQRSTUVXYZ.ABCDEFGHIJKLMNOPQRS.VeryVeryLongLongLongModuleSentence"
    message = build_message(application(), procid)
    assert "<11>Oct  1 12:44:01 upptec_slack_robot VeryVeryLongLongLongModuleSenten Hello PaperTrail!" == message
  end

  defp application, do: Keyword.get(@meta, :application, nil)
  defp build_message(app, procid) do
    LoggerPapertrailBackend.MessageBuilder.build("Hello PaperTrail!", :error, app, @timestamp, procid)
  end
end
