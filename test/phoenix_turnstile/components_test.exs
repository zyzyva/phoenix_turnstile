defmodule PhoenixTurnstile.ComponentsTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import PhoenixTurnstile.ConfigHelper

  alias PhoenixTurnstile.Components

  describe "widget/1" do
    test "renders nothing when Turnstile is not enabled" do
      with_temp_config([site_key: nil, secret_key: nil], fn ->
        html = render_component(&Components.widget/1, id: "test-widget")

        # Should render nothing when disabled
        refute html =~ "phx-hook=\"TurnstileHook\""
        refute html =~ "turnstile-container"
      end)
    end

    test "renders widget div when Turnstile is enabled" do
      with_temp_config([site_key: "test-site-key", secret_key: "test-secret"], fn ->
        html = render_component(&Components.widget/1, id: "test-widget")

        assert html =~ "id=\"test-widget\""
        assert html =~ "phx-hook=\"TurnstileHook\""
        assert html =~ "data-sitekey=\"test-site-key\""
        assert html =~ "id=\"turnstile-container\""
      end)
    end

    test "applies custom class to widget" do
      with_temp_config([site_key: "test-site-key", secret_key: "test-secret"], fn ->
        html =
          render_component(&Components.widget/1, id: "test-widget", class: "my-custom-class")

        assert html =~ "class=\"my-custom-class\""
      end)
    end

    test "uses custom container_id" do
      with_temp_config([site_key: "test-site-key", secret_key: "test-secret"], fn ->
        html =
          render_component(&Components.widget/1,
            id: "test-widget",
            container_id: "custom-container"
          )

        assert html =~ "id=\"custom-container\""
        refute html =~ "id=\"turnstile-container\""
      end)
    end
  end

  describe "widget_with_loading/1" do
    test "renders nothing when Turnstile is not enabled" do
      with_temp_config([site_key: nil, secret_key: nil], fn ->
        html = render_component(&Components.widget_with_loading/1, id: "test-widget")

        refute html =~ "phx-hook=\"TurnstileHook\""
        refute html =~ "turnstile-container"
      end)
    end

    test "renders widget with loading indicator when enabled" do
      with_temp_config([site_key: "test-site-key", secret_key: "test-secret"], fn ->
        html = render_component(&Components.widget_with_loading/1, id: "test-widget")

        assert html =~ "id=\"test-widget\""
        assert html =~ "phx-hook=\"TurnstileHook\""
        assert html =~ "data-sitekey=\"test-site-key\""
        assert html =~ "id=\"turnstile-container\""
        assert html =~ "Loading verification..."
        assert html =~ "animate-spin"
      end)
    end

    test "uses custom loading text" do
      with_temp_config([site_key: "test-site-key", secret_key: "test-secret"], fn ->
        html =
          render_component(&Components.widget_with_loading/1,
            id: "test-widget",
            loading_text: "Please wait..."
          )

        assert html =~ "Please wait..."
        refute html =~ "Loading verification..."
      end)
    end

    test "applies custom class to widget container" do
      with_temp_config([site_key: "test-site-key", secret_key: "test-secret"], fn ->
        html =
          render_component(&Components.widget_with_loading/1,
            id: "test-widget",
            class: "flex justify-center"
          )

        assert html =~ "class=\"flex justify-center\""
      end)
    end
  end
end
