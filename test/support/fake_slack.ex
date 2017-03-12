defmodule Slack.FakeSlack do
  use Plug.Router
  import Plug.Conn

  plug :match
  plug :dispatch

  def start_link do
    Plug.Adapters.Cowboy.http(__MODULE__, [], port: 51345, dispatch: dispatch())
    Application.put_env(:slack, :url, "http://localhost:51345")
  end

  defp dispatch do
    [{
      :_,
      [
        {"/ws", Slack.FakeSlackWebsocket, []},
        {:_, Plug.Adapters.Cowboy.Handler, {__MODULE__, []}}
      ]
    }]
  end

  get "/api/rtm.start" do
    conn = fetch_query_params(conn)

    pid = Application.get_env(:slack, :pid)
    send pid, {:token, conn.query_params["token"]}

    response = ~S(
      {
        "url": "ws://localhost:51345/ws",
        "self": { "id": "U0123abcd", "name": "bot" },
        "team": { "id": "T4567abcd", "name": "Example Team" },
        "bots": [{ "id": "U0123abcd", "name": "bot" }],
        "channels": [],
        "groups": [],
        "users": [],
        "ims": []
      }
    )

    send_resp(conn, 200, response)
  end

  match _ do
    IO.inspect conn
    send_resp(conn, 200, "")
  end
end
