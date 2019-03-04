# Bind a player_id to the TCP socket and the handler process.
# The goal is to send message to any socket from any place.
defmodule Tanks.Players do
  use GenServer
  require Logger


  def start_link([]) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end


  def register(player_id, handler, socket) do
    GenServer.call(__MODULE__, {:register, player_id, handler, socket})
  end


  def unregister(player_id) do
    GenServer.cast(__MODULE__, {:unregister, player_id})
  end


  def notify(player_id, event, data) do
    GenServer.cast(__MODULE__, {:notify, player_id, Map.put(data, :type, event)})
  end


  def broadcast(event, data) do
    GenServer.cast(__MODULE__, {:broadcast, Map.put(data, :type, event)})
  end


  def online() do
    GenServer.call(__MODULE__, :online)
  end



  def init(state) do
    {:ok, state}
  end


  def handle_call({:register, player_id, handler, socket}, _from, state) do
    state = Map.put(state, player_id, %{handler: handler, socket: socket})
    {:reply, :ok, state} # TODO: Reject with {:err, :name_already_registered} when name is used.
  end


  def handle_call(:online, _from, state) do
    reply = Enum.reduce(state, %{}, fn ({player_id, _player}, acc) ->
      Map.put(acc, player_id, %{id: player_id})
    end)
    {:reply, reply, state}
  end


  def handle_cast({:unregister, player_id}, state) do
    state = Map.delete(state, player_id)
    {:noreply, state}
  end


  def handle_cast({:notify, player_id, data}, state) do
    map = Map.get(state, player_id)
    if map, do: :ranch_tcp.send(map.socket, Poison.encode!(data) <> "\n")
    {:noreply, state}
  end


  def handle_cast({:broadcast, data}, state) do
    Enum.map(state, fn {_player_id, map} ->
      :ranch_tcp.send(map.socket, Poison.encode!(data) <> "\n")
    end)
    {:noreply, state}
  end
end
