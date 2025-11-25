defmodule ClickdealerSearch.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts the scheduler to check for vehicles every 30 minutes
      ClickdealerSearch.Scheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ClickdealerSearch.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
