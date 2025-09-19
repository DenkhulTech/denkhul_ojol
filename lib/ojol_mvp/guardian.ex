defmodule OjolMvp.Guardian do
  use Guardian, otp_app: :ojol_mvp

  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(%{"sub" => id}) do
    case OjolMvp.Accounts.get_user(id) do
      {:ok, user} -> {:ok, user}
      {:error, :not_found} -> {:error, :resource_not_found}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end
end
