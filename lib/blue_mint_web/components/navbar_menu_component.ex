defmodule BlueMintWeb.Components.NavbarMenuComponent do
  use BlueMintWeb, :html

  # Credit: https://www.creative-tim.com/twcomponents/component/pure-css-dropdown-using-focus-within
  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center">
      <div class="relative inline-block text-left">
        <button
          class="inline-flex justify-center w-full px-4 py-2 text-sm font-medium text-gray-700 transition duration-150 ease-in-out bg-white border border-purple-300 rounded hover:text-gray-500 focus:border-purple-300 focus:shadow-outline-purple active:bg-purple-50 active:text-gray-800"
          type="button"
          aria-haspopup="true"
          aria-expanded="true"
          aria-controls="menu-items"
          phx-click={JS.show(to: "#dropdown-menu")}
        >
          Options &nbsp;<span aria-hidden="true">&rarr;</span>
        </button>
        <div id="dropdown-menu" class="hidden">
          <div
            class="absolute right-0 w-48 mt-2 bg-white border border-purple-200 divide-y divide-purple-100 rounded shadow-lg"
            aria-labelledby="menu-button"
            id="menu-items"
            role="menu"
            phx-click-away={JS.hide(to: "#dropdown-menu")}
          >
            <div class="px-4 py-3">
              <.live_component
                module={BlueMintWeb.Live.Components.UsernameComponent}
                id="username-widget"
                user_id={@user_id}
              >
              </.live_component>
            </div>
            <div class="py-1" phx-click={JS.hide(to: "#dropdown-menu")}>
              <a
                href="https://github.com/jflowaa/blue_mint"
                target="_blank"
                class="text-gray-700 flex justify-between w-full px-4 py-2 text-sm leading-5 text-left"
                role="menuitem"
              >
                Source Code
              </a>
              <a
                href="https://jack-develops.com/projects"
                class="text-gray-700 flex justify-between w-full px-4 py-2 text-sm leading-5 text-left"
                role="menuitem"
              >
                More projects
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
