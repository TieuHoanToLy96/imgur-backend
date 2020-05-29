defmodule ImgurBackend.App.Consumer do
  require Logger
  use GenServer
  use AMQP

  alias ImgurBackend.App.{AmqpConnectionManager, Tools}
  alias ImgurBackend.Worker.Mainworker

  @queue_base "task_pool"
  @queue_error "#{@queue_base}_error"
  @queue_sync "#{@queue_base}_sync"
  @queue_sync_pancake "#{@queue_sync}_pancake"

  # client
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def channel_available(chan) do
    Logger.info("go chan")
    GenServer.cast(__MODULE__, {:channel_available, chan})
  end

  # server
  def init(:ok) do
    AmqpConnectionManager.request_channel(__MODULE__)
    {:ok, nil}
  end

  def handle_cast({:channel_available, chan}, _state) do
    Logger.info("CHANNEL_AVAILABLE")

    AMQP.Queue.declare(chan, @queue_error, durable: true)

    AMQP.Queue.declare(
      chan,
      @queue_sync_pancake,
      durable: true,
      arguments: [
        {"x-dead-letter-exchange", :longstr, ""},
        {"x-dead-letter-routing-key", :longstr, @queue_error}
      ]
    )

    minutes = [1, 2, 5, 10, 15, 20, 18, 21, 24, 27, 30]

    Enum.each(
      minutes,
      &AMQP.Queue.declare(
        chan,
        "wait_m_#{Tools.add_prefix(&1, 2)}",
        durable: true,
        arguments: [
          {"x-dead-letter-exchange", :longstr, ""},
          {"x-dead-letter-routing-key", :longstr, @queue_sync_pancake},
          {"x-message-ttl", :signedint, 60000 * &1}
        ]
      )
    )

    {:ok, consumer_tag} = Basic.consume(chan, @queue_sync_pancake)

    Application.put_env(:imgur_backend, :rmq_chan_sync, chan)
    Application.put_env(:imgur_backend, :rmq_sync_consumer_tag, consumer_tag, persistent: true)

    {:noreply, chan}
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
