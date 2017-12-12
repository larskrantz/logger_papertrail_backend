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

  describe "when mapping elixir logging levels to syslog priorities" do
    test "should map :debug to 15" do
      assert 15 == check_priority(:debug)
    end
    test "should map :info to 14" do
      assert 14 == check_priority(:info)
    end
    test "should map :warn to 12" do
      assert 12 == check_priority(:warn)
    end
    test "should map :error to 11" do
      assert 11 == check_priority(:error)
    end
  end


  defp application, do: Keyword.get(@meta, :application, nil)
  defp build_message(app, procid, log_level) do
    LoggerPapertrailBackend.MessageBuilder.build("Hello PaperTrail!", log_level, app, @timestamp, procid)
  end
  defp build_message(app, procid), do: build_message(app, procid, :error)
  defp check_priority(level) do
    message = build_message("appname", "procid", level)
    String.slice(message, 1, 2) |> String.to_integer()
  end
end
