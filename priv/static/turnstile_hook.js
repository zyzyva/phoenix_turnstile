/**
 * Cloudflare Turnstile LiveView Hook
 *
 * Implements graceful failure - never blocks users even if Turnstile fails.
 * All errors result in bypass tokens that allow processing to continue.
 *
 * Usage:
 *
 * 1. Import and register this hook in your app.js:
 *    import TurnstileHook from "./turnstile_hook"
 *
 *    let liveSocket = new LiveSocket("/live", Socket, {
 *      hooks: { TurnstileHook }
 *    })
 *
 * 2. Add to your LiveView template:
 *    <div
 *      phx-hook="TurnstileHook"
 *      id="turnstile-widget"
 *      data-sitekey={@turnstile_site_key}
 *    >
 *      <div id="turnstile-container"></div>
 *    </div>
 *
 * 3. Handle the callback in your LiveView:
 *    def handle_event("turnstile_callback", %{"token" => token}, socket) do
 *      # Verify token with PhoenixTurnstile.Verification.verify_token(token)
 *      {:noreply, assign(socket, :turnstile_token, token)}
 *    end
 */

const TurnstileHook = {
  mounted() {
    try {
      const sitekey = this.getSitekey()
      if (!sitekey) {
        return this.sendBypassToken("no-key")
      }

      this.sitekey = sitekey
      this.containerId = this.getContainerId()
      this.loadTurnstileScript()
      this.setupResetHandler()
    } catch (error) {
      console.error("❌ Turnstile: Initialization error", error)
      this.sendBypassToken("init-error")
    }
  },

  getSitekey() {
    const sitekey = this.el.getAttribute('data-sitekey')
    return sitekey && sitekey !== "undefined" && sitekey !== "null" ? sitekey : null
  },

  getContainerId() {
    const containerId = this.el.getAttribute('data-container-id')
    return containerId && containerId !== "undefined" && containerId !== "null" ? containerId : 'turnstile-container'
  },

  sendBypassToken(reason) {
    console.warn(`⚠️ Turnstile: Bypassing verification - ${reason}`)
    this.pushEvent("turnstile_callback", { token: `bypass-${reason}` })
  },

  loadTurnstileScript() {
    if (window.turnstile) {
      return this.scheduleRender()
    }

    if (document.querySelector('script[src*="turnstile"]')) {
      return this.waitForTurnstile()
    }

    this.injectScript()
  },

  injectScript() {
    const script = document.createElement('script')
    script.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit'
    script.async = true
    script.defer = true
    script.onload = () => this.scheduleRender()
    script.onerror = () => this.sendBypassToken("script-error")
    document.head.appendChild(script)
  },

  waitForTurnstile() {
    const checkInterval = setInterval(() => {
      if (window.turnstile) {
        clearInterval(checkInterval)
        this.scheduleRender()
      }
    }, 100)

    // Timeout after 5 seconds
    setTimeout(() => {
      if (!window.turnstile) {
        clearInterval(checkInterval)
        this.sendBypassToken("script-timeout")
      }
    }, 5000)
  },

  scheduleRender() {
    setTimeout(() => this.renderWidget(), 100)
  },

  setupResetHandler() {
    this.handleEvent("reset_turnstile", () => {
      if (window.turnstile && this.widgetId !== undefined) {
        try {
          window.turnstile.reset(this.widgetId)
          console.log("🔄 Turnstile: Widget reset")
        } catch (error) {
          console.warn("⚠️ Turnstile: Reset failed", error)
        }
      }
    })
  },

  renderWidget() {
    try {
      if (!this.canRender()) return

      const container = this.getContainer()
      if (!container) return

      this.clearContainer(container)
      this.widgetId = this.createWidget(container)
    } catch (error) {
      console.error("❌ Turnstile: Render error", error)
      this.sendBypassToken("render-error")
    }
  },

  canRender() {
    if (!window.turnstile) {
      this.sendBypassToken("no-api")
      return false
    }

    if (typeof window.turnstile.render !== 'function') {
      console.error("❌ Turnstile: render method not found. Make sure element ID is not 'turnstile'")
      this.sendBypassToken("no-render-method")
      return false
    }

    if (this.widgetId !== undefined) {
      return false
    }

    return true
  },

  getContainer() {
    const container = document.getElementById(this.containerId)
    if (!container) {
      console.error(`❌ Turnstile: Container with id="${this.containerId}" not found`)
      this.sendBypassToken("no-container")
      return null
    }

    // Check if widget already rendered
    if (container.querySelector('iframe, [id^="cf-chl-widget"]')) {
      return null
    }

    return container
  },

  clearContainer(container) {
    container.innerHTML = ''
  },

  createWidget(container) {
    try {
      // Set a timeout to bypass if widget doesn't complete in 6 seconds
      this.timeoutId = setTimeout(() => {
        console.warn("⚠️ Turnstile: Widget timeout after 6 seconds, bypassing")
        this.sendBypassToken("timeout")
      }, 6000)

      const widgetId = window.turnstile.render(container, {
        sitekey: this.sitekey,
        theme: 'auto',
        size: 'invisible',
        callback: (token) => {
          console.log("✅ Turnstile: Token generated successfully")
          if (this.timeoutId) {
            clearTimeout(this.timeoutId)
            this.timeoutId = null
          }
          this.pushEvent("turnstile_callback", { token })
        },
        'error-callback': () => {
          console.warn("⚠️ Turnstile: Widget error")
          if (this.timeoutId) {
            clearTimeout(this.timeoutId)
            this.timeoutId = null
          }
          this.sendBypassToken("widget-error")
        },
        'expired-callback': () => {
          console.log("⏰ Turnstile: Token expired")
          this.pushEvent("turnstile_callback", { token: null })
        },
        'timeout-callback': () => {
          console.warn("⚠️ Turnstile: Widget timeout callback")
          if (this.timeoutId) {
            clearTimeout(this.timeoutId)
            this.timeoutId = null
          }
          this.sendBypassToken("widget-timeout")
        }
      })
      console.log("✅ Turnstile: Invisible widget loaded successfully")
      return widgetId
    } catch (error) {
      console.error("❌ Turnstile: Failed to create widget", error)
      if (this.timeoutId) {
        clearTimeout(this.timeoutId)
        this.timeoutId = null
      }
      this.sendBypassToken("create-error")
      return undefined
    }
  },

  destroyed() {
    // Clear timeout if still pending
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
      this.timeoutId = null
    }

    // Remove widget
    if (window.turnstile && this.widgetId !== undefined) {
      try {
        window.turnstile.remove(this.widgetId)
        this.widgetId = undefined
        console.log("🗑️ Turnstile: Widget removed")
      } catch (error) {
        console.warn("⚠️ Turnstile: Cleanup error", error)
      }
    }
  }
}

export default TurnstileHook
