defmodule Console.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ConsoleWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:console, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Console.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Console.Finch},
      # Start a worker by calling: Console.Worker.start_link(arg)
      # {Console.Worker, arg},
      # Start to serve requests, typically the last entry
      ConsoleWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Console.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ConsoleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
