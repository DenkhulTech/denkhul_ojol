defmodule OjolMvp.Repo do
  use Ecto.Repo,
    otp_app: :ojol_mvp,
    adapter: Ecto.Adapters.Postgres
end
