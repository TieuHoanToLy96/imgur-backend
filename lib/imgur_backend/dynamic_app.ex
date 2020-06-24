defmodule ImgurBackend.DynamicApp do
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def children() do
    DynamicSupervisor.which_children(__MODULE__)
  end
end
