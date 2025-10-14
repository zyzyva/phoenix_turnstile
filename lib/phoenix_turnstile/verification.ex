defmodule PhoenixTurnstile.Verification do
  @moduledoc """
  Cloudflare Turnstile verification module for bot protection.

  Provides graceful failure handling - verification failures never block users.
  All errors are logged but processing continues to ensure good user experience.

  ## Configuration

  Set these in your application config:

      config :phoenix_turnstile,
        site_key: System.get_env("TURNSTILE_SITE_KEY"),
        secret_key: System.get_env("TURNSTILE_SECRET_KEY")

  ## Development

  In development, test keys are used automatically unless explicitly configured.
  Set `USE_PROD_TURNSTILE=true` to use production keys in development.
  """

  require Logger

  @verification_url "https://challenges.cloudflare.com/turnstile/v0/siteverify"
  @timeout 5_000

  @doc """
  Verifies a Turnstile token with Cloudflare.

  Always returns `{:ok, true}` for bypass tokens or when verification fails
  to ensure users are never blocked by Turnstile issues.

  ## Returns

  - `{:ok, true}` - Token verified or bypassed gracefully
  - `{:ok, false}` - Verification failed (still allows processing)
  - `{:error, reason}` - Service error (still allows processing)

  ## Examples

      iex> PhoenixTurnstile.Verification.verify_token("valid-token")
      {:ok, true}

      iex> PhoenixTurnstile.Verification.verify_token("bypass-test")
      {:ok, true}

      iex> PhoenixTurnstile.Verification.verify_token(nil)
      {:error, "Invalid token"}
  """
  @spec verify_token(binary()) :: {:ok, boolean()} | {:error, String.t()}
  def verify_token(token) when is_binary(token) do
    case {bypass_token?(token), secret_key()} do
      {true, _} -> handle_bypass_token(token)
      {_, nil} -> handle_no_secret_key()
      {_, secret} -> perform_verification(token, secret)
    end
  end

  def verify_token(_invalid), do: {:error, "Invalid token"}

  @doc """
  Checks if Turnstile is configured and enabled.

  Returns `true` if both site key and secret key are configured.

  ## Examples

      iex> PhoenixTurnstile.Verification.enabled?()
      true
  """
  @spec enabled?() :: boolean()
  def enabled? do
    site_key() != nil && secret_key() != nil
  end

  @doc """
  Gets the Turnstile site key for client-side widget.

  Returns the configured site key or `nil` if not configured.

  ## Examples

      iex> PhoenixTurnstile.Verification.site_key()
      "1x00000000000000000000AA"
  """
  @spec site_key() :: String.t() | nil
  def site_key do
    Application.get_env(:phoenix_turnstile, :site_key)
  end

  # Private functions

  defp secret_key do
    Application.get_env(:phoenix_turnstile, :secret_key)
  end

  defp bypass_token?(token), do: String.starts_with?(token, "bypass-")

  defp handle_bypass_token(token) do
    Logger.warning("Turnstile: Accepting bypass token - #{token}")
    {:ok, true}
  end

  defp handle_no_secret_key do
    Logger.warning("Turnstile: No secret key configured, skipping verification")
    {:ok, true}
  end

  defp perform_verification(token, secret_key) do
    @verification_url
    |> Req.post(json: build_request_body(token, secret_key), receive_timeout: @timeout)
    |> handle_verification_response()
  end

  defp build_request_body(token, secret_key) do
    %{secret: secret_key, response: token}
  end

  # Response handling with explicit pattern matching
  defp handle_verification_response({:ok, %{status: 200, body: %{"success" => true}}}),
    do: {:ok, true}

  defp handle_verification_response(
         {:ok, %{status: 200, body: %{"success" => false, "error-codes" => errors}}}
       ) do
    Logger.warning("Turnstile: Verification failed - #{inspect(errors)}")
    {:ok, false}
  end

  defp handle_verification_response({:ok, %{status: status}}) do
    Logger.error("Turnstile: Unexpected API status #{status}")
    {:error, "Verification service error"}
  end

  defp handle_verification_response({:error, reason}) do
    Logger.error("Turnstile: Request failed - #{inspect(reason)}")
    {:error, "Could not verify captcha"}
  end
end
