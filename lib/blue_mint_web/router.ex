defmodule BlueMintWeb.Router do
  use BlueMintWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BlueMintWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :add_user_id
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BlueMintWeb do
    pipe_through :browser

    live "/", LobbyBrowserLive.Index, :index
    live "/new", LobbyBrowserLive.Index, :new
    live "/lobby/:lobby_id", LobbyLive.Index, :new
  end

  # Other scopes may use custom stacks.
  # scope "/api", BlueMintWeb do
  #   pipe_through :api
  # end

  defp add_user_id(conn, _opts) do
    if is_nil(get_session(conn, :user_id)) do
      conn
      |> put_session(
        :user_id,
        BlueMint.generate_unique_identifier()
      )
    else
      conn
    end
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:blue_mint, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BlueMintWeb.Telemetry
    end
  end
end
