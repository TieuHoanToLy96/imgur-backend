defmodule ImgurBackend.Worker.Mainworker do
  require Logger
  use AMQP

  def is_json_format(<<_::utf8, t::binary>>), do: is_json_format(t)
  def is_json_format(<<>>), do: true
  def is_json_format(_), do: false

  def assign_job(chan, tag, _redelivered, payload) do
    obj =
      if is_json_format(payload),
        do: Jason.decode!(payload),
        else: :erlang.binary_to_term(payload)

    case obj["action"] do
      "test" -> IO.inspect("testttttt")
    end

    Basic.ack(chan, tag)
  rescue
    exception ->
      Logger.error("|> ERROR in Mainworker.assign_job/4: #{inspect(exception)}")
      Logger.error("|> payload |> #{inspect(payload)}")
      Basic.ack(chan, tag)

      reraise(exception, System.stacktrace())
  end
end
