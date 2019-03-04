# Game:
# %{
#   id: uuid
#   map: map,
#   player_1: some_player_id,
#   player_2: another_player_id,
#   players: %{
#     player_1: %{ name: "Foo", gold: 42 },
#     player_2: %{ name: "Foo", gold: 42 },
#   },
#   current_player: :player_1 | :player_2,
#   units: %{
#     some_unit_id: unit,
#     ...
#   }
# }
#
# Map:
# %{
#   id: uuid,
#   name: "Foo",
#   width: 42,
#   height: 42,
#   special_tiles: {
#     [x, y]: :hills | :water | :forest | :gas_station | :player_1_headquarter | :player_2_headquarter
#   }
# }
#
# Unit:
# %{
#   id: uuid
#   owner: :player_1 | :player_2,
#   x: 42,
#   y: 42,
#   unit_type: :land_raider | ...,
#   health: 42,
#   fuel: 42,
#   actions: 42,
# }
defmodule Tanks.Game do
  use GenServer, restart: :temporary
  alias Tanks.{Lobbies, Players, GameState}


  def start_link(game) do
    GenServer.start_link(__MODULE__, game, name: via_tuple(game.id))
  end


  def via_tuple(id) do
    {:via, Registry, {Tanks.Registry, {:game, id}}}
  end


  def get(id) do
    case Registry.lookup(Tanks.Registry, {:game, id}) do
      [{pid, nil}] -> info(pid)
      _ -> nil
    end
  end


  def info(pid) do
    GenServer.call(pid, {:info})
  end


  def basic_info(pid) do
    GenServer.call(pid, {:basic_info})
  end


  def player_ends_turn(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:player_ends_turn, player_id})
  end


  def player_buys_unit(game_id, player_id, unit_type, tile) do
    GenServer.call(via_tuple(game_id), {:player_buys_unit, player_id, unit_type, tile})
  end


  def player_moves_unit(game_id, player_id, moving_unit_id, destination_tile) do
    GenServer.call(via_tuple(game_id), {:player_moves_unit, player_id, moving_unit_id, destination_tile})
  end


  def player_attacks_unit(game_id, player_id, attacking_unit_id, target_tile) do
    GenServer.call(via_tuple(game_id), {:player_attacks_unit, player_id, attacking_unit_id, target_tile})
  end


  def player_leaves_game(game_id, player_id, reason) do
    GenServer.call(via_tuple(game_id), {:player_leaves_game, player_id, reason})
  end



  def init(game) do
    game = game
      |> Map.put(:players, %{
        player_1: %{ gold: 100_000 },
        player_2: %{ gold: 100_000 }
      })
      |> Map.put(:winner, nil)
      |> Map.put(:current_player, :player_1)
      |> Map.put(:units, %{})
      |> Map.put(:turn, 1)

    Lobbies.close_lobbies_opened_by_player(game.player_1)
    Lobbies.close_lobbies_opened_by_player(game.player_2)
    Players.notify(game.player_1, "game_started", %{game: game})
    Players.notify(game.player_2, "game_started", %{game: game})

    {:ok, game}
  end


  def handle_call({:info}, _from, game) do
    {:reply, game, game}
  end


  def handle_call({:basic_info}, _from, game) do
    basic_info = Map.take(game, [:id, :player_1, :player_2])
    {:reply, basic_info, game}
  end


  def handle_call({:player_ends_turn, player_id}, _from, game) do
    if game[game.current_player] == player_id do
      new_current_player = if game.current_player == :player_1, do: :player_2, else: :player_1
      new_current_player_id = game[new_current_player]

      game = game
        |> Map.put(:current_player, new_current_player)
        |> Map.update!(:turn, fn (turn) -> turn + 1 end)
        |> GameState.reset_units(new_current_player)

      Players.notify(player_id,             "turn_started", %{current_player: new_current_player, turn: game.turn})
      Players.notify(new_current_player_id, "turn_started", %{current_player: new_current_player, turn: game.turn})

      {:reply, {:ok, new_current_player}, game}
    else
      {:reply, {:error, :not_active_player}, game}
    end
  end


  def handle_call({:player_buys_unit, player_id, unit_type_id, tile = [x,y]}, _from, game) do
    if game[game.current_player] == player_id do
      unit_type = Tanks.UnitType.get(unit_type_id)
      if unit_type.cost <= game.players[game.current_player].gold do
        if game.units["#{x}_#{y}"] == nil do
          game = game
            |> GameState.remove_gold(game.current_player, unit_type.cost)
            |> GameState.add_unit(game.current_player, unit_type, tile)

          gold         = game.players[game.current_player].gold
          unit         = game.units["#{x}_#{y}"]
          other_player = game.current_player == :player_1 && :player_2 || :player_1

          Players.notify(player_id,          "unit_bought", %{unit: unit, gold: gold})
          Players.notify(game[other_player], "unit_bought", %{unit: unit, gold: nil})

          {:reply, {:ok}, game}
        else
          {:reply, {:error, :tile_already_taken}, game}
        end
      else
        {:reply, {:error, :not_enough_gold}, game}
      end
    else
      {:reply, {:error, :not_active_player}, game}
    end
  end


  def handle_call({:player_moves_unit, player_id, unit_id, tile = [x, y]}, _from, game) do
    if game[game.current_player] == player_id do
      if game.units["#{x}_#{y}"] == nil do
        unit         = Enum.find(Map.values(game.units), fn (unit) -> unit.id == unit_id end)
        origin       = [unit.x, unit.y]
        game         = GameState.move_unit(game, unit, tile)
        unit         = game.units["#{x}_#{y}"]
        other_player = game.current_player == :player_1 && :player_2 || :player_1

        Players.notify(player_id,          "unit_moved", %{unit: unit, origin: origin, destination: tile})
        Players.notify(game[other_player], "unit_moved", %{unit: unit, origin: origin, destination: tile})

        {:reply, {:ok}, game}
      else
        {:reply, {:error, :tile_already_taken}, game}
      end
    else
      {:reply, {:error, :not_active_player}, game}
    end
  end


  def handle_call({:player_attacks_unit, player_id, attacking_unit_id, [x, y]}, _from, game) do
    if game[game.current_player] == player_id do
      attacking_unit = GameState.get_unit(game, attacking_unit_id)
      target_unit    = game.units["#{x}_#{y}"]

      if target_unit != nil and target_unit.owner != attacking_unit.owner do
        if GameState.can_attack(attacking_unit) do
          if GameState.is_in_range(attacking_unit, target_unit) do
            {game, result} = GameState.attack_unit(game, attacking_unit, target_unit)
            other_player   = game.current_player == :player_1 && :player_2 || :player_1
            winner         = GameState.check_victory_conditions(game)

            Players.notify(player_id,          "fight_ended", %{attacking_unit: attacking_unit, target_unit: target_unit, result: result, winner: winner})
            Players.notify(game[other_player], "fight_ended", %{attacking_unit: attacking_unit, target_unit: target_unit, result: result, winner: winner})

            {:reply, {:ok}, put_in(game.winner, winner)}
          else
            {:reply, {:error, :out_of_range}, game}
          end
        else
          {:reply, {:error, :cant_attack}, game}
        end
      else
        {:reply, {:error, :no_target}, game}
      end
    else
      {:reply, {:error, :not_active_player}, game}
    end
  end


  def handle_call({:player_leaves_game, player_id, _reason}, _from, game) do
    if game.winner == nil do
      leaving_player   = game.player_1 == player_id && :player_1 || :player_2
      remaining_player = leaving_player == :player_1 && :player_2 || :player_1

      Players.notify(game[remaining_player], "player_left", %{winner: remaining_player})
      {:stop, :shutdown, :ok, put_in(game.winner, remaining_player)}
    end
  end
end
