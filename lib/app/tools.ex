defmodule ImgurBackend.App.Tools do
  def validate_email(email) do
    Regex.match?(
      ~r/^(([^<>()\[\]\.,;:\s@\"]+(\.[^<>()\[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/,
      email
    )
  end

  def get_error_message_from_changeset(changeset) do
    errors = changeset.errors

    Enum.reduce(errors, "", fn {_key, {message, _}}, acc ->
      if is_empty?(acc),
        do: message,
        else: acc <> ", #{message}"
    end)
  end

  def is_empty?(value) when value in [nil, "null", "", "undefined", %{}, []], do: true
  def is_empty?(_), do: false

  def to_int(el) when el in [nil, "", "null", "undefined", "", [], %{}], do: 0
  def to_int(el) when is_bitstring(el), do: String.to_integer(el)
  def to_int(el) when is_integer(el), do: el
  def to_int(_), do: 0

  def enqueue_task(task, opts \\ []) when is_list(opts) do
    r_channel = Application.get_env(:imgur_backend, :rmq_chan_sync)
    r_queue = System.get_env("R_QUEUE") || "task_pool_sync_imgur"

    task_msg =
      if Keyword.get(opts, :to_binary),
        do: :erlang.term_to_binary(task),
        else: Jason.encode!(task)

    IO.inspect([r_channel, "", r_queue, task_msg, true], label: "kkkkkkk")
    AMQP.Basic.publish(r_channel, "", r_queue, task_msg, persistent: true)
  end

  def enqueue(queue, payload, opts \\ []) when is_list(opts) do
    r_channel = Application.get_env(:imgur_backend, :rmq_chan_sync)

    task =
      if Keyword.get(opts, :to_binary),
        do: :erlang.term_to_binary(payload),
        else: Jason.encode!(payload)

    AMQP.Basic.publish(r_channel, "", queue, task, persistent: true)
  end

  def add_prefix(value, length, prefix \\ "0") do
    cond do
      is_bitstring(value) ->
        if String.length(value) < length do
          value = prefix <> value
          add_prefix(value, length, prefix)
        else
          value
        end

      is_integer(value) ->
        add_prefix(Integer.to_string(value), length, prefix)

      true ->
        throw("invalid input")
    end
  end
end
