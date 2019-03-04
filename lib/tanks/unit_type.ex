defmodule Tanks.UnitType do
  def get("recon") do
    %{
      id: "recon",
      name: "Recon",
      move: 8,
      max_fuel: 80,
      vision: 5,
      main_weapon: nil,
      max_ammo: nil,
      secondary_weapon: :submachine_gun,
      armor_type: :light,
      cost: 4000
    }
  end


  def get("artillery") do
    %{
      id: "artillery",
      name: "Artillery",
      move: 5,
      max_fuel: 50,
      vision: 3,
      main_weapon: :mortar,
      max_ammo: 9,
      secondary_weapon: nil,
      armor_type: :light,
      cost: 6000
    }
  end


  def get("tank") do
    %{
      id: "tank",
      name: "Tank",
      move: 6,
      max_fuel: 70,
      vision: 3,
      main_weapon: :light_cannon,
      max_ammo: 9,
      secondary_weapon: :submachine_gun,
      armor_type: :medium,
      cost: 7000
    }
  end


  def get("medium_tank") do
    %{
      id: "medium_tank",
      name: "Medium tank",
      move: 5,
      max_fuel: 50,
      vision: 2,
      main_weapon: :medium_cannon,
      max_ammo: 8,
      secondary_weapon: :submachine_gun,
      armor_type: :heavy,
      cost: 16000
    }
  end


  def get("refiller") do
    %{
      id: "refiller",
      name: "Refiller",
      move: 6,
      max_fuel: 70,
      vision: 2,
      main_weapon: nil,
      max_ammo: nil,
      secondary_weapon: nil,
      armor_type: :light,
      cost: 5000
    }
  end


  def base_damage(nil, _any_armor), do: 0

  def base_damage(:submachine_gun, :light), do: 60
  def base_damage(:submachine_gun, :medium), do: 30
  def base_damage(:submachine_gun, :heavy), do: 10

  def base_damage(:light_cannon, :light), do: 80
  def base_damage(:light_cannon, :medium), do: 50
  def base_damage(:light_cannon, :heavy), do: 30

  def base_damage(:medium_cannon, :light), do: 110
  def base_damage(:medium_cannon, :medium), do: 70
  def base_damage(:medium_cannon, :heavy), do: 50

  def base_damage(:mortar, :light), do: 110
  def base_damage(:mortar, :medium), do: 70
  def base_damage(:mortar, :heavy), do: 30
end
