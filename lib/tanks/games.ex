defmodule Tanks.Games do
  use GenServer


  def start_link([]) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end


  def create(map, player_1, player_2) do
    GenServer.call(__MODULE__, {:create, SecureRandom.hex(3), map, player_1, player_2})
  end


  def game_for_player(player_id) do
    Enum.find(all(), fn (game) ->
      game.player_1 == player_id or game.player_2 == player_id
    end)
  end


  def all do
    children = Supervisor.which_children(Tanks.GamesSupervisor)
    Enum.map(children, fn ({_, pid, _, _}) ->
      Tanks.Game.basic_info(pid)
    end)
  end


  def seed() do
    Task.async(fn ->
      IO.inspect("Seed game...")
      mac = "SephiChanMac"
      win = "SephiChanWindows"

      {:ok, lobby_id} = Tanks.Lobbies.open(mac, Tanks.Board.get(1))
      {:ok, game_id} = Tanks.Lobbies.add_player(lobby_id, win)
      Tanks.Game.player_buys_unit(game_id, mac, "medium_tank", [5,5])
      Tanks.Game.player_buys_unit(game_id, mac, "artillery", [5,3])
      Tanks.Game.player_buys_unit(game_id, mac, "recon", [5,2])
      Tanks.Game.player_buys_unit(game_id, mac, "tank", [4,3])
      Tanks.Game.player_ends_turn(game_id, mac)

      Tanks.Game.player_buys_unit(game_id, win, "recon", [6,3])
      Tanks.Game.player_ends_turn(game_id, win)
    end)
  end


  def init(state) do
    {:ok, state}
  end


  def handle_call({:create, game_id, map, player_1_id, player_2_id}, _from, state) do
    game = %{
      id:       game_id,
      player_1: player_1_id,
      player_2: player_2_id,
      map:      map
    }

    {:ok, pid} = DynamicSupervisor.start_child(Tanks.GamesSupervisor, {Tanks.Game, game})
    Process.monitor(pid)
    {:reply, {:ok, game.id}, state}
  end


  def handle_info({:DOWN, _, _, _, _}, state) do
    games = Tanks.Games.all()
    if games == [] do
      Tanks.Games.seed()
    end
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
