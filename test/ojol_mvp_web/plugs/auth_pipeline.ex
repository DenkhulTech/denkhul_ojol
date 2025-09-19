defmodule OjolMvpWeb.Plugs.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :ojol_mvp,
    error_handler: OjolMvpWeb.Plugs.AuthErrorHandler,
    module: OjolMvp.Guardian

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, ensure: true
end
