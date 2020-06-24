defmodule ImgurBackend.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(ImgurBackend.Repo, []),
      supervisor(ImgurBackendWeb.Endpoint, [])
      # supervisor(ImgurBackend.App.AmqpConnectionManager, [])
    ]

    children000 =
      if System.get_env("MIX_ENV") == "dev",
        do:
          children ++
            [
              # Start Amqp
              supervisor(ImgurBackend.DynamicApp, [])
            ],
        else: children

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ImgurBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ImgurBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
