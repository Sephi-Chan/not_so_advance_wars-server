# There is one TcpHandler per user connected to the game.
# It only stores the user identifier given at opening to pass it along following commands.
defmodule Tanks.TcpHandler do
  @behaviour :ranch_protocol
  use GenServer
  alias Tanks.{Players, Lobbies, Board, Games, Game}
  require Logger


  def start_link(ref, socket, transport, _opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end


  def init(args) do
    {:ok, args} # dumb.
  end


  def init(ref, socket, transport) do
    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, true}])
    :gen_server.enter_loop(__MODULE__, [], %{socket: socket, transport: transport})
  end


  def handle_info({:tcp, socket, json}, state) do
    data = Poison.decode!(json)
    IO.inspect({:incoming_message, Map.get(state, :player_id), data})
    state = apply(data["type"], data, socket, state)
    {:noreply, state}
  end


  def handle_info({:tcp_closed, socket}, state = %{ player_id: player_id }) do
    Players.unregister(player_id)
    Lobbies.close_lobbies_opened_by_player(player_id)
    Players.broadcast("player_left_server", %{player_id: player_id})

    running_game = Games.game_for_player(player_id)
    if running_game do Game.player_leaves_game(running_game.id, player_id, :brutal) end

    :ranch_tcp.close(socket)
    {:stop, :normal, state}
  end


  # If the player never sent the "player_joins_server" message to authenticate.
  def handle_info({:tcp_closed, socket}, state) do
    :ranch_tcp.close(socket)
    {:stop, :normal, state}
  end


  def handle_cast({:player_joined_server, player_id}, state) do
    {:noreply, Map.put(state, :player_id, player_id)}
  end



  defp apply("player_joins_server", %{"player_id" => player_id}, socket, state) do
    :ok = Players.register(player_id, self(), socket)
    online_players    = Players.online()
    open_lobbies      = Lobbies.available(player_id)
    running_game_info = Games.game_for_player(player_id)
    running_game      = running_game_info && Game.get(running_game_info.id) || nil

    Players.broadcast("player_joined_server", %{player_id: player_id})
    Players.notify(player_id, "connection_succeeded", %{online_players: online_players, open_lobbies: open_lobbies, running_game: running_game})

    Map.put(state, :player_id, player_id)
  end


  defp apply("what_is_online", _data, _socket, state) do
    online_players = Players.online()
    open_lobbies   = Lobbies.available(state.player_id)

    Players.notify(state.player_id, "this_is_online", %{online_players: online_players, open_lobbies: open_lobbies})

    state
  end


  defp apply("player_leaves_game", _data, _socket, state) do
    game = Games.game_for_player(state.player_id)
    Game.player_leaves_game(game.id, state.player_id, :soft)
    state
  end


  defp apply("player_opens_lobby", _data, _socket, state) do
    Lobbies.open(state.player_id, Board.get(1))
    state
  end


  defp apply("player_joins_lobby", %{"lobby_id" => lobby_id}, _socket, state) do
    Lobbies.add_player(lobby_id, state.player_id)
    state
  end


  defp apply("end_turn", _data, _socket, state) do
    game = Games.game_for_player(state.player_id)
    Game.player_ends_turn(game.id, state.player_id)
    state
  end


  defp apply("buy_unit", %{"unit_type" => unit_type, "tile" => tile}, _socket, state) do
    game = Games.game_for_player(state.player_id)
    Game.player_buys_unit(game.id, state.player_id, unit_type, tile)
    state
  end


  defp apply("move_unit", %{"unit_id" => unit_id, "tile" => tile}, _socket, state) do
    game = Games.game_for_player(state.player_id)
    Game.player_moves_unit(game.id, state.player_id, unit_id, tile)
    state
  end


  defp apply("attack_unit", %{"unit_id" => attacking_unit_id, "tile" => target_tile}, _socket, state) do
    game = Games.game_for_player(state.player_id)
    Game.player_attacks_unit(game.id, state.player_id, attacking_unit_id, target_tile)
    state
  end


  defp apply(unknown_command, _data, _socket, state) do
    Logger.info "Received unknown command #{unknown_command}..."
    state
  end
end
