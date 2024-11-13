defmodule BlueMint.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BlueMintWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:blue_mint, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BlueMint.PubSub},
      Registry.child_spec(
        keys: :duplicate,
        name: BlueMint.EventRegistry.LobbyUpdate
      ),
      BlueMint.Common.ProcessMonitor,
      BlueMint.Common.NameManager,
      BlueMint.Lobby.Server,
      BlueMint.Game.ServerSupervisor,
      # Start a worker by calling: BlueMint.Worker.start_link(arg)
      # {BlueMint.Worker, arg},
      # Start to serve requests, typically the last entry
      BlueMintWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BlueMint.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BlueMintWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
