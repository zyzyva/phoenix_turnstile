defmodule PhoenixTurnstile do
  @moduledoc """
  Cloudflare Turnstile integration for Phoenix applications.

  PhoenixTurnstile provides seamless integration of Cloudflare Turnstile bot protection
  into Phoenix and LiveView applications with graceful failure handling that never blocks users.

  ## Features

  - **Graceful failure handling** - Verification failures never block users
  - **Automatic CSP configuration** - Igniter-based installer adds required CSP directives
  - **Phoenix components** - Drop-in LiveView component for easy widget rendering
  - **LiveView hooks** - JavaScript hook for client-side widget management
  - **Bypass mode** - Development-friendly bypass tokens for testing
  - **Zero-config development** - Works out of the box with test keys

  ## Installation

  Add `phoenix_turnstile` to your list of dependencies in `mix.exs`:

      def deps do
        [
          {:phoenix_turnstile, github: "zyzyva/phoenix_turnstile"}
        ]
      end

  Then run the installer:

      mix igniter.install phoenix_turnstile

  This will:
  - Add Turnstile configuration to your config files
  - Update CSP headers in your router to allow Turnstile domains
  - Copy the JavaScript hook to your assets directory
  - Update your app.js to register the hook

  ## Configuration

  Add to your config:

      # config/config.exs
      config :phoenix_turnstile,
        site_key: System.get_env("TURNSTILE_SITE_KEY"),
        secret_key: System.get_env("TURNSTILE_SECRET_KEY")

  Set environment variables:

      export TURNSTILE_SITE_KEY="your_site_key"
      export TURNSTILE_SECRET_KEY="your_secret_key"

  ## Usage in LiveView

  Add the component to your LiveView template:

      <.live_component
        module={PhoenixTurnstile.Components.Widget}
        id="turnstile-widget"
      />

  Handle the token in your LiveView:

      def handle_event("turnstile_callback", %{"token" => token}, socket) do
        case PhoenixTurnstile.Verification.verify_token(token) do
          {:ok, true} ->
            # Token verified, process the form
            {:noreply, assign(socket, :turnstile_verified, true)}

          _ ->
            # Verification failed or errored, but we allow processing anyway
            {:noreply, assign(socket, :turnstile_verified, false)}
        end
      end

  ## Development

  In development, Turnstile works without configuration using test keys.
  All verification requests will succeed to enable easy testing.

  ## Security

  Turnstile verification failures are logged but never block users. This ensures:
  - No false positives blocking legitimate users
  - Graceful degradation if Cloudflare is unreachable
  - Better user experience than hard-blocking CAPTCHAs

  For more information, see the module documentation:
  - `PhoenixTurnstile.Verification` - Backend token verification
  - `PhoenixTurnstile.Components` - Phoenix LiveView components
  """

  @doc """
  Returns the version of PhoenixTurnstile.
  """
  @spec version() :: String.t()
  def version do
    "0.1.0"
  end

  @doc """
  Checks if Turnstile is enabled in the current environment.

  Delegates to `PhoenixTurnstile.Verification.enabled?/0`.
  """
  defdelegate enabled?, to: PhoenixTurnstile.Verification

  @doc """
  Gets the Turnstile site key for client-side use.

  Delegates to `PhoenixTurnstile.Verification.site_key/0`.
  """
  defdelegate site_key, to: PhoenixTurnstile.Verification

  @doc """
  Verifies a Turnstile token.

  Delegates to `PhoenixTurnstile.Verification.verify_token/1`.
  """
  defdelegate verify_token(token), to: PhoenixTurnstile.Verification
end
