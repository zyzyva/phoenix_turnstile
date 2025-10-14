defmodule PhoenixTurnstile.Components do
  @moduledoc """
  Phoenix LiveView components for Cloudflare Turnstile integration.

  Provides drop-in components for rendering Turnstile widgets in LiveView applications.

  ## Usage

  In your LiveView template:

      <PhoenixTurnstile.Components.widget id="turnstile-widget" />

  Or with custom options:

      <PhoenixTurnstile.Components.widget
        id="turnstile-widget"
        class="my-custom-class"
        container_id="my-turnstile-container"
      />

  ## Important: Avoid id="turnstile"

  **DO NOT** use `id="turnstile"` as it creates a global `window.turnstile` variable
  that conflicts with the Cloudflare Turnstile API. Always use a different ID like
  `id="turnstile-widget"` or `id="my-turnstile"`.

  ## Handling the Callback

  Then handle the callback event in your LiveView:

      def handle_event("turnstile_callback", %{"token" => token}, socket) do
        case PhoenixTurnstile.verify_token(token) do
          {:ok, true} -> {:noreply, assign(socket, :verified, true)}
          _ -> {:noreply, assign(socket, :verified, false)}
        end
      end

  You can also manually reset the widget:

      {:noreply, push_event(socket, "reset_turnstile", %{})}
  """

  use Phoenix.Component

  @doc """
  Renders a Turnstile widget.

  ## Attributes

  - `id` (required) - Unique identifier for the hook element
  - `class` (optional) - CSS classes to apply to the widget container
  - `container_id` (optional) - ID for the inner container div (defaults to "turnstile-container")

  ## Examples

      <PhoenixTurnstile.Components.widget id="my-turnstile" />

      <PhoenixTurnstile.Components.widget
        id="my-turnstile"
        class="flex justify-center my-4"
        container_id="custom-container"
      />
  """
  attr(:id, :string, required: true, doc: "Unique identifier for the hook element")
  attr(:class, :string, default: "", doc: "CSS classes for the widget container")

  attr(:container_id, :string,
    default: "turnstile-container",
    doc: "ID for the inner container"
  )

  def widget(assigns) do
    site_key = PhoenixTurnstile.Verification.site_key() || ""
    enabled = PhoenixTurnstile.Verification.enabled?()

    assigns =
      assigns
      |> assign(:site_key, site_key)
      |> assign(:enabled, enabled)

    ~H"""
    <div
      :if={@enabled}
      id={@id}
      phx-hook="TurnstileHook"
      data-sitekey={@site_key}
      data-container-id={@container_id}
      class={@class}
    >
      <div id={@container_id}></div>
    </div>
    """
  end

  @doc """
  Renders a Turnstile widget with loading indicator.

  Shows a loading message while the widget initializes.

  ## Attributes

  - `id` (required) - Unique identifier for the hook element (avoid "turnstile")
  - `class` (optional) - CSS classes to apply to the widget container
  - `container_id` (optional) - ID for the inner container div (defaults to "turnstile-container")
  - `loading_text` (optional) - Text to display while loading (defaults to "Loading verification...")

  ## Examples

      <PhoenixTurnstile.Components.widget_with_loading id="turnstile-widget" />

      <PhoenixTurnstile.Components.widget_with_loading
        id="my-turnstile"
        loading_text="Please wait..."
        container_id="my-container"
      />
  """
  attr(:id, :string, required: true)
  attr(:class, :string, default: "")
  attr(:container_id, :string, default: "turnstile-container")
  attr(:loading_text, :string, default: "Loading verification...")

  def widget_with_loading(assigns) do
    site_key = PhoenixTurnstile.Verification.site_key() || ""
    enabled = PhoenixTurnstile.Verification.enabled?()

    assigns =
      assigns
      |> assign(:site_key, site_key)
      |> assign(:enabled, enabled)

    ~H"""
    <div :if={@enabled} class={@class}>
      <div
        id={@id}
        phx-hook="TurnstileHook"
        data-sitekey={@site_key}
        data-container-id={@container_id}
      >
        <div id={@container_id}>
          <div class="flex items-center justify-center p-4 text-sm text-gray-600">
            <svg
              class="animate-spin h-5 w-5 mr-2"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                class="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                stroke-width="4"
              >
              </circle>
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              >
              </path>
            </svg>
            <%= @loading_text %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
