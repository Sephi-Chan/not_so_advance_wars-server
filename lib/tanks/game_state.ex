defmodule Tanks.GameState do
  alias Tanks.{UnitType, Board}

  def remove_gold(game, player, removed_gold) do
    update_in(game, [:players, player, :gold], fn (gold) -> gold - removed_gold end)
  end


  def add_unit(game, player, unit_type, [x, y]) do
    unit = %{
      id:           SecureRandom.uuid(),
      moved:        false,
      fired:        false,
      owner:        player,
      x:            x,
      y:            y,
      fuel:         unit_type.max_fuel,
      ammo:         unit_type.max_ammo,
      count:        10,
      unit_type_id: unit_type.id
    }

    put_in(game, [:units, "#{x}_#{y}"], unit)
  end


  def get_unit(game, unit_id) do
    {_, unit} = Enum.find(game.units, fn ({_, unit}) -> unit.id == unit_id end)
    unit
  end


  def move_unit(game, unit, [x, y]) do
    {_, game} = pop_in(game, [:units, "#{unit.x}_#{unit.y}"])
    fired = unit.unit_type_id != "artillery"
    unit  = Map.merge(unit, %{x: x, y: y, moved: true, fired: fired})
    put_in(game, [:units, "#{x}_#{y}"], unit)
  end


  def reset_units(game, player) do
    update_in(game.units, fn (units) ->
      Enum.reduce(units, %{}, fn ({key, unit}, acc) ->
        Map.put(acc, key, if unit.owner == player do
          Map.merge(unit, %{moved: false, fired: false})
        else
          unit
        end)
      end)
    end)
  end


  def attack_unit(game, attacking_unit, target_unit) do
    # Attack.
    attacker_unit_type     = UnitType.get(attacking_unit.unit_type_id)
    target_unit_type       = UnitType.get(target_unit.unit_type_id)
    attacker_weapon        = get_weapon(attacker_unit_type, attacking_unit.ammo)
    attacker_weapon_type   = attacker_weapon && attacker_unit_type[attacker_weapon]
    target_armor_type      = target_unit_type.armor_type
    attacker_base_damage   = UnitType.base_damage(attacker_weapon_type, target_armor_type)
    attacker_damage        = attacking_unit.count/10 * attacker_base_damage
    target_terrain         = game.map.special_tiles["#{target_unit.x}_#{target_unit.y}"] || :plain
    target_defense_factor  = 1 - Board.defense_bonus(target_terrain)
    attacker_final_damage  = attacker_damage * target_defense_factor * 1.2
    target_losses          = round(10 * attacker_final_damage/100)
    remaining_target_count = max(target_unit.count - target_losses, 0)

    # Ripost (none if attacker is artillery).
    attacker_armor_type      = attacker_unit_type.armor_type
    target_weapon            = get_weapon(target_unit_type, target_unit.ammo)
    target_weapon_type       = target_weapon && target_unit_type[target_weapon]
    target_base_damage       = UnitType.base_damage(target_weapon_type, attacker_armor_type)
    target_damage            = remaining_target_count/10 * target_base_damage
    attacker_terrain         = game.map.special_tiles["#{attacking_unit.x}_#{attacking_unit.y}"] || :plain
    attacker_defense_factor  = 1 - Board.defense_bonus(attacker_terrain)
    target_final_damage      = target_damage * attacker_defense_factor
    attacker_losses          = (attacking_unit.unit_type_id == "artillery" or target_unit.unit_type_id == "artillery") && 0 || round(10 * target_final_damage/100)
    remaining_attacker_count = max(attacking_unit.count - attacker_losses, 0)

    attacking_unit_after = Map.merge(attacking_unit, %{
      # ammo:  attacker_weapon == :main_weapon and attacking_unit.ammo - 1 || attacking_unit.ammo,
      count: remaining_attacker_count,
      moved: true,
      fired: true
    })

    game = if remaining_attacker_count == 0 do
      {_, game} = pop_in(game, [:units, "#{attacking_unit.x}_#{attacking_unit.y}"])
      game
    else
      put_in(game, [:units, "#{attacking_unit.x}_#{attacking_unit.y}"], attacking_unit_after)
    end

    target_unit_after = Map.merge(target_unit, %{
      # ammo:  target_weapon == :main_weapon and target_unit.ammo - 1 || target_unit.ammo,
      count: remaining_target_count
    })

    game = if remaining_target_count == 0 do
      {_, game} = pop_in(game, [:units, "#{target_unit.x}_#{target_unit.y}"])
      game
    else
      put_in(game, [:units, "#{target_unit.x}_#{target_unit.y}"], target_unit_after)
    end

    result = %{
      attacking_unit: attacking_unit_after,
      target_unit:    target_unit_after
    }

    {game, result}
  end


  def can_attack(%{unit_type_id: unit_type_id, moved: moved, fired: fired}) do
    (unit_type_id == "artillery" and !moved and !fired) or !fired
  end


  def is_in_range(%{unit_type_id: unit_type_id, x: ox, y: oy}, %{x: tx, y: ty}) do
    radius = if unit_type_id == "artillery", do: 4, else: 1
    Enum.find(tiles_around(ox, oy, radius), fn ({x, y}) -> x == tx and y == ty end)
  end


  defp tiles_around(x, y, radius) do
    List.delete(List.flatten(for i <- (x - radius)..(x + radius) do
      for j <- (y - radius)..(y + radius) do
        {i, j}
      end
    end), {x, y})
  end


  defp get_weapon(unit_type, ammo) do
    cond do
      unit_type.main_weapon && 1 <= ammo -> :main_weapon
      unit_type.secondary_weapon -> :secondary_weapon
      true -> nil
    end
  end


  def check_victory_conditions(game) do
    units_per_player = Enum.reduce(game.units, %{player_1: 0, player_2: 0}, fn ({_, unit}, acc) ->
      Map.update!(acc, unit.owner, fn (count) -> count + 1 end)
    end)

    cond do
      units_per_player.player_1 == 0 -> :player_2
      units_per_player.player_2 == 0 -> :player_1
      true -> nil
    end
  end
end
