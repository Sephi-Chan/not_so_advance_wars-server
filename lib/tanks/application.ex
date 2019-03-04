defmodule Tanks.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Registry, keys: :unique, name: Tanks.Registry},
      Tanks.Players,
      Tanks.Lobbies,
      Tanks.Games,
      {DynamicSupervisor, name: Tanks.GamesSupervisor, strategy: :one_for_one}
    ]

    :ranch.start_listener(:my_tcp_listener, :ranch_tcp, [{:port, 4040}], Tanks.TcpHandler, [])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tanks.Supervisor]
    result = Supervisor.start_link(children, opts)

    Tanks.Games.seed()

    result
  end
end
