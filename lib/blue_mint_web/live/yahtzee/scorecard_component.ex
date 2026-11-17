defmodule BlueMintWeb.Live.Yahtzee.ScorecardComponent do
  use BlueMintWeb, :html

  def render(assigns) do
    ~H"""
    <div class="block p-6 mr-3 mt-3 rounded-lg shadow-lg bg-white dark:bg-gray-800 dark:text-white w-100 shrink-0">
      <h2 class="text-gray-700 dark:text-white text-base mb-4 text-md">
        <%= @scorecard.user_id %>'s Scorecard
      </h2>
      <div class="flex flex-col">
        <table class="table-fixed text-xl">
          <thead class="border-b">
            <th scope="col" class="px-4 text-left">Category</th>
            <th scope="col" class="text-left">Score</th>
          </thead>
          <tbody>
            <%= for category <- BlueMint.Yahtzee.Scorecard.upper_section_keys() do %>
              <tr>
                <td class="text-md">
                  <%= "#{category}" |> String.replace("_", " ") |> :string.titlecase() %>
                </td>
                <td class="text-center border-b">
                  <%= Map.get(@scorecard, category) %>
                </td>
              </tr>
            <% end %>
            <tr>
              <td class="text-md">Upper section bonus</td>
              <td class="text-center"><%= Map.get(@scorecard, :upper_section_bonus) %></td>
            </tr>
            <tr>
              <td class="text-md">Upper section</td>
              <td class="text-center"><%= Map.get(@scorecard, :upper_section) %></td>
            </tr>
            <%= for category <- BlueMint.Yahtzee.Scorecard.lower_section_keys() do %>
              <tr>
                <td class="text-md">
                  <%= "#{category}" |> String.replace("_", " ") |> :string.titlecase() %>
                </td>
                <td class="text-center border-b">
                  <%= Map.get(@scorecard, category) %>
                </td>
              </tr>
            <% end %>
            <tr>
              <td class="text-md">Yahtzee bonus</td>
              <%= if Map.get(@scorecard, :yahtzee) == 50 do %>
                <td class="text-center cursor-pointer border-b">
                  <%= Map.get(@scorecard, :yahtzee_bonus) %>
                </td>
              <% else %>
                <td class="text-center"><%= Map.get(@scorecard, :yahtzee_bonus) %></td>
              <% end %>
            </tr>
            <tr>
              <td class="text-md">Lower section</td>
              <td class="text-center"><%= Map.get(@scorecard, :lower_section) %></td>
            </tr>
            <tr>
              <td class="text-md">Grand total</td>
              <td class="text-center"><%= Map.get(@scorecard, :grand_total) %></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
