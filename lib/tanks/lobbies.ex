defmodule Tanks.Lobbies do
  use GenServer
  alias Tanks.{Players, Games}


  def start_link([]) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end


  def open(player_id, map) do
    GenServer.call(__MODULE__, {:open, player_id, map})
  end


  def close_lobbies_opened_by_player(player_id) do
    GenServer.cast(__MODULE__, {:close_lobbies_opened_by_player, player_id})
  end


  def add_player(lobby_id, player_id) do
    GenServer.call(__MODULE__, {:add_player, lobby_id, player_id})
  end


  def available(player_id) do
    GenServer.call(__MODULE__, {:available, player_id})
  end



  def init(state) do
    {:ok, state}
  end


  def handle_cast({:close_lobbies_opened_by_player, player_id}, state) do
    state = Enum.reduce(state, %{}, fn ({lobby_id, lobby}, acc) ->
      if lobby.player_1 == player_id do
        Players.broadcast("lobby_closed", %{lobby_id: lobby.id})
        acc
      else
        Map.put(acc, lobby_id, lobby)
      end
    end)
    {:noreply, state}
  end


  def handle_call({:add_player, lobby_id, player_2}, _from, state) do
    lobby = state[lobby_id]
    if lobby != nil and lobby.player_1 != player_2 do
      {:ok, game_id} = Games.create(lobby.map, lobby.player_1, player_2)
      {:reply, {:ok, game_id}, Map.delete(state, lobby_id)}
    else
      {:reply, {:error, :cheat}, state}
    end
  end


  def handle_call({:open, player_id, map}, _from, state) do
    if length(lobbies_opened_by_player(player_id, state)) == 0 do
      lobby = %{id: SecureRandom.uuid(), player_1: player_id, map: map}
      Players.broadcast("lobby_opened", %{lobby_id: lobby.id, player_1: lobby.player_1})
      {:reply, {:ok, lobby.id}, Map.put(state, lobby.id, lobby)}
    else
      {:reply, {:error, :already_opened_lobby}, state}
    end
  end


  def handle_call({:available, _player_id}, _from, state) do
    available_lobbies = Enum.reduce(state, %{}, fn ({lobby_id, lobby}, acc) ->
      Map.put(acc, lobby_id, lobby)
    end)
    {:reply, available_lobbies, state}
  end


  defp lobbies_opened_by_player(player_id, state) do
    Enum.reduce(state, [], fn ({lobby_id, lobby}, acc) ->
      if lobby.player_1 == player_id, do: [lobby_id|acc], else: acc
    end)
  end
end
