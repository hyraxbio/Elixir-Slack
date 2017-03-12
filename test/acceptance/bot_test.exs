defmodule Slack.Acceptance.BotTest do
  use ExUnit.Case

  defmodule Bot do
    use Slack

    def handle_event(message = %{type: "message", text: text}, slack, state) do
      send_message(String.reverse(text), message.channel, slack)
      {:ok, state}
    end
    def handle_event(_, _, state), do: {:ok, state}
  end

  test "can start a connection" do
    pid = Slack.FakeSlack.start_link()
    Application.put_env(:slack, :pid, self())

    {:ok, pid} =  Slack.Bot.start_link(Bot, [], "xyz")

    assert_received {:token, "xyz"} # rtm.start method was successful
    assert_receive {:websocket_connected, websocket_pid} # successfully connected to websocket

    send_message_to_client(websocket_pid, "hello!")

    assert_receive {:bot_message, %{"text" => "!olleh"}}
  end

  def send_message_to_client(pid, message) do
    send pid, JSX.encode!(%{type: "message", text: message, channel: "C0123abc"})
  end
end
