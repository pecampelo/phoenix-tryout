defmodule ConsoleWeb.Router do
  use ConsoleWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {ConsoleWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", ConsoleWeb.Live do
    pipe_through(:browser)

    live("/", Index, :home)
    live("/create", Index, :create)
    live("/update", Index, :update)
  end
end
