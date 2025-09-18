# lib/ojol_mvp_web/router.ex
defmodule OjolMvpWeb.Router do
  use OjolMvpWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OjolMvpWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", OjolMvpWeb do
    pipe_through :browser
    get "/", PageController, :home
  end

  # API ROUTES - ADD THIS SECTION
scope "/api", OjolMvpWeb do
  pipe_through :api

  # User routes
  put "/users/:id/location", UserController, :update_location
  resources "/users", UserController, except: [:new, :edit]

  # Custom order routes HARUS SEBELUM resources
  get "/orders/available", OrderController, :available_orders
  put "/orders/:id/accept", OrderController, :accept
  put "/orders/:id/start", OrderController, :start_trip
  put "/orders/:id/complete", OrderController, :complete

  # Order resources SETELAH custom routes
  resources "/orders", OrderController, except: [:new, :edit]

  # Rating routes
  resources "/ratings", RatingController, except: [:new, :edit]
end

  # Other scopes may use custom stacks.
  # scope "/api", OjolMvpWeb do
  #   pipe_through :api
  # end
end
