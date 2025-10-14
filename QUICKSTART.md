# Phoenix Turnstile Quick Start

Get Cloudflare Turnstile working in your Phoenix LiveView app in 5 minutes.

## Installation

### 1. Add dependency

```elixir
# mix.exs
def deps do
  [
    {:phoenix_turnstile, github: "zyzyva/phoenix_turnstile"}
  ]
end
```

### 2. Install

```bash
mix deps.get
mix igniter.install phoenix_turnstile
```

The installer automatically sets up everything including importing and registering the JavaScript hooks.

### 3. Add to your LiveView

```elixir
defmodule MyAppWeb.ContactLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <form phx-submit="submit">
      <PhoenixTurnstile.Components.widget_with_loading id="turnstile-widget" />
      <button type="submit">Submit</button>
    </form>
    """
  end

  def handle_event("turnstile_callback", %{"token" => _token}, socket) do
    # Token received automatically
    {:noreply, socket}
  end

  def handle_event("submit", _params, socket) do
    # Process form...
    {:noreply, socket}
  end
end
```

## That's it!

The widget works immediately on localhost without any configuration. For production, set:

```bash
export TURNSTILE_SITE_KEY="your_production_key"
export TURNSTILE_SECRET_KEY="your_production_secret"
```

## Important

**DO NOT use `id="turnstile"`** - it creates a naming collision. Use `id="turnstile-widget"` instead.

## Verification (Optional)

To actually verify the token server-side:

```elixir
def handle_event("turnstile_callback", %{"token" => token}, socket) do
  case PhoenixTurnstile.verify_token(token) do
    {:ok, true} ->
      {:noreply, assign(socket, :verified, true)}

    _ ->
      {:noreply, assign(socket, :verified, false)}
  end
end
```

## Configuration

The installer automatically configures:

- **Development/Test**: Uses Cloudflare test keys (work on localhost)
- **Production**: Uses environment variables

No manual configuration needed for local development!

## Troubleshooting

### Widget doesn't appear

1. Check browser console for errors
2. Make sure you're NOT using `id="turnstile"` (use `id="turnstile-widget"`)
3. Verify the installer completed successfully

### More help

See the full [README.md](README.md) for complete documentation.
