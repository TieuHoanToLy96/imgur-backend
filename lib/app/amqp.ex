defmodule ImgurBackend.App.AmqpConnectionManager do
  use GenServer
  use AMQP
  require Logger

  alias ImgurBackend.App.{Consumer}
  alias ImgurBackend.Worker.Mainworker

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    import Supervisor.Spec

    children = [
      worker(Consumer, [])
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: ImgurBackend.App.ConsumerSupervisor
    )

    establish_new_connection()
  end

  def establish_new_connection do
    host = System.get_env("R_HOST") || "localhost"
    vhost = System.get_env("R_VHOST") || "v1"
    username = System.get_env("R_USERNAME") || "guest"
    password = System.get_env("R_PASSWORD") || "guest"
    port = System.get_env("R_PORT") || "5672"

    amqp_uri = "amqp://#{username}:#{password}@#{host}:#{port}/#{vhost}"

    Logger.info("URI: #{inspect(amqp_uri)}")

    case Connection.open(amqp_uri) do
      {:ok, conn} ->
        Process.link(conn.pid)
        {:ok, {conn, %{}}}

      {:error, reason} ->
        Logger.error("AMQP FAILED TO OPEN CONNECTION: #{inspect(reason)}")

        :timer.sleep(5000)
        establish_new_connection()
    end
  end

  def request_channel(consumer) do
    GenServer.cast(__MODULE__, {:chan_request, consumer})
  end

  def handle_cast({:chan_request, consumer}, {conn, channel_mappings}) do
    Logger.info("HANDLE CAST CONSUMER")
    new_mappings = store_channel_mapping(conn, consumer, channel_mappings)
    chan = Map.get(new_mappings, consumer)
    consumer.channel_available(chan)

    Logger.info("Connected! #{inspect(new_mappings)}")
    {:noreply, {conn, new_mappings}}
  end

  defp store_channel_mapping(conn, consumer, channel_mappings) do
    # Only create new channel for non-existing consumer
    Map.put_new_lazy(channel_mappings, consumer, fn -> create_channel(conn) end)
  end

  defp create_channel(conn) do
    {:ok, chan} = Channel.open(conn)

    chan
  end

  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, chan) do
    spawn(fn -> consume(chan, tag, redelivered, payload) end)
    {:noreply, chan}
  end

  def consume(chan, tag, redelivered, payload) do
    Mainworker.assign_job(chan, tag, redelivered, payload)
  end
end
