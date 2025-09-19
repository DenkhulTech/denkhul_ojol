defmodule OjolMvpWeb.Router do
  use OjolMvpWeb, :router
  import Phoenix.LiveDashboard.Router

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
    plug :put_secure_browser_headers
    # Add CORS headers if needed
    # plug CORSPlug, origin: ["https://yourapp.com"]
  end

  # Auth pipeline for protected routes
  pipeline :authenticated do
    plug OjolMvpWeb.Plugs.AuthPipeline
  end

  # Rate limiting pipeline (implement rate limiting plug)
  pipeline :rate_limited do
    plug :rate_limit
  end

  scope "/", OjolMvpWeb do
    pipe_through :browser
    live_dashboard "/dashboard", metrics: OjolMvpWeb.Telemetry
    get "/", PageController, :home
  end

  scope "/api-docs", OjolMvpWeb do
    pipe_through :api

    get "/", ApiDocsController, :ui
    get "/spec.json", ApiDocsController, :index
  end

  # Public API routes (with rate limiting)
  scope "/api", OjolMvpWeb do
    pipe_through [:api, :rate_limited]

    # Authentication endpoints
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login

    # User registration (public)
    post "/users", UserController, :create

    # Health check endpoint
    # get "/health", HealthController, :check
  end

  # Semi-public API routes (less sensitive, with rate limiting)
  scope "/api", OjolMvpWeb do
    pipe_through [:api, :rate_limited]

    # Public ratings view (for checking driver/customer ratings)
    get "/users/:user_id/ratings", RatingController, :user_ratings
  end

  # Protected API routes (authenticated users only)
  scope "/api", OjolMvpWeb do
    pipe_through [:api, :authenticated]

    # Auth routes (protected)
    post "/auth/refresh", AuthController, :refresh
    post "/auth/logout", AuthController, :logout

    # User routes (protected) - no index, no bulk operations
    # View own profile
    get "/profile", UserController, :profile
    # View specific user (own only)
    get "/users/:id", UserController, :show
    # Update user (own only)
    put "/users/:id", UserController, :update
    # Delete user (own only)
    delete "/users/:id", UserController, :delete
    # Update location (own only)
    put "/users/:id/location", UserController, :update_location

    # Order routes (protected)
    # Get user's orders
    get "/orders", OrderController, :my_orders
    # Create new order (customers only)
    post "/orders", OrderController, :create
    # View specific order
    get "/orders/:id", OrderController, :show
    # Update order (customer, pending only)
    put "/orders/:id", OrderController, :update
    # Cancel order (customer only)
    delete "/orders/:id", OrderController, :delete

    # Driver-specific order routes
    # Available orders for drivers
    get "/orders/available", OrderController, :available_orders
    # Accept order (drivers only)
    put "/orders/:id/accept", OrderController, :accept
    # Start trip (assigned driver only)
    put "/orders/:id/start", OrderController, :start_trip
    # Complete trip (assigned driver only)
    put "/orders/:id/complete", OrderController, :complete

    # Rating routes (protected)
    # Ratings created by user
    get "/ratings", RatingController, :my_ratings
    # Ratings received by user
    get "/ratings/received", RatingController, :received_ratings
    # Create new rating
    post "/ratings", RatingController, :create
    # View specific rating
    get "/ratings/:id", RatingController, :show
    # Update rating (own only, time limited)
    put "/ratings/:id", RatingController, :update
    # Delete rating (own only, time limited)
    delete "/ratings/:id", RatingController, :delete
  end

  # Admin routes (if needed in the future)
  # scope "/api/admin", OjolMvpWeb do
  #   pipe_through [:api, :authenticated, :admin_only]
  #
  #   get "/users", UserController, :admin_index
  #   get "/orders", OrderController, :admin_index
  #   get "/ratings", RatingController, :admin_index
  # end

  # Private functions for plugs

  defp rate_limit(conn, _opts) do
    # Implement rate limiting logic here
    # You can use libraries like ExRated or Hammer
    # For now, just pass through
    conn
  end

  # Error handling
  if Mix.env() != :prod do
    scope "/dev" do
      pipe_through :browser
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
