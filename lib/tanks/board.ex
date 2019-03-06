defmodule Tanks.Board do
  def get(_anything) do
    %{
      id: 1,
      name: "Amber",
      columns: 24,
      rows: 17,
      special_tiles: %{
        "1_1" => :hills,
        "24_1" => :hills,
        "5_5" => :hills,
        "11_8" => :hills,
        "12_8" => :hills,
        "10_9" => :hills,
        "11_9" => :hills,
        "18_2" => :forest,
        "19_2" => :forest,
        "20_3" => :forest,
        "4_10" => :forest,
        "5_9" => :forest,
        "5_10" => :forest,
        "5_11" => :forest,
        "6_11" => :forest,
        "17_15" => :forest,
        "18_16" => :forest,
        "9_1" => :forest,
        "10_1" => :forest,
        "10_2" => :forest,
        "10_12" => :forest,
        "1_16" => :hills,
        "1_17" => :hills,
        "2_17" => :hills,
        "24_6" => :hills,
        "24_7" => :hills,
        "24_8" => :hills,
        "23_7" => :hills,
        "23_6" => :forest,
        "8_1" => :hills,
        "12_9" => :forest,
        "12_10" => :forest,
        "1_5" => :hills,
        "1_6" => :forest,
        "10_8" => :forest,
        "11_7" => :forest,
        "9_9" => :forest,
        "15_4" => :forest,
        "17_3" => :forest,
        "9_16" => :forest,
        "8_17" => :forest,
        "9_17" => :hills,
        "10_17" => :forest,
        "24_16" => :forest,
        "23_17" => :hills,
        "24_17" => :hills,
        "16_8" => :forest,
        "17_8" => :forest,
        "18_8" => :forest,
        "18_9" => :forest,
        "17_7" => :forest,
      },
      buildings: %{
        "3_3" => :player_1_headquarter,
        "21_14" => :player_2_headquarter
      }
    }
  end


  def defense_bonus(:plain), do: 0
  def defense_bonus(:forest), do: 0.2
  def defense_bonus(:hills), do: 0.4
  def defense_bonus(:mountains), do: 0.4
end
