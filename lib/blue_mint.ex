defmodule BlueMint do
  @lobby_messages_topic "lobby_messages_"
  @user_messages_topic "user_messages_"
  @username_change_topic "username_change_"
  @game_state_topic "game_state_"

  def subscribe_to_lobby_messages(identifier),
    do: Phoenix.PubSub.subscribe(BlueMint.PubSub, lobby_messages_topic(identifier))

  def broadcast_lobby_message(identifier, message),
    do:
      Phoenix.PubSub.broadcast(
        BlueMint.PubSub,
        lobby_messages_topic(identifier),
        {:message, message}
      )

  def broadcast_lobby_closed(identifier),
    do: Phoenix.PubSub.broadcast(BlueMint.PubSub, lobby_messages_topic(identifier), :lobby_closed)

  def subscribe_to_user_messages(identifier),
    do: Phoenix.PubSub.subscribe(BlueMint.PubSub, user_messages_topic(identifier))

  def broadcast_user_message(identifier, message),
    do:
      Phoenix.PubSub.broadcast(
        BlueMint.PubSub,
        user_messages_topic(identifier),
        {:message, message}
      )

  def subscribe_to_username_changes(identifier),
    do: Phoenix.PubSub.subscribe(BlueMint.PubSub, username_change_topic(identifier))

  def broadcast_username_change(identifier, previous_username, new_username),
    do:
      Phoenix.PubSub.broadcast(
        BlueMint.PubSub,
        username_change_topic(identifier),
        {:username_change, previous_username, new_username}
      )

  def subscribe_to_game_state(identifier),
    do: Phoenix.PubSub.subscribe(BlueMint.PubSub, game_state_topic(identifier))

  def broadcast_game_state(identifier, payload \\ :update),
    do: Phoenix.PubSub.broadcast(BlueMint.PubSub, game_state_topic(identifier), payload)

  def generate_unique_identifier(),
    do: :crypto.strong_rand_bytes(32) |> Base.encode64(padding: false) |> binary_part(0, 32)

  def pretty_atom(atom),
    do:
      atom
      |> Atom.to_string()
      |> String.split("_")
      |> Enum.map(fn x -> String.capitalize(x) end)
      |> Enum.join(" ")

  defp lobby_messages_topic(identifier), do: "#{@lobby_messages_topic}_#{identifier}"
  defp user_messages_topic(identifier), do: "#{@user_messages_topic}_#{identifier}"
  defp username_change_topic(identifier), do: "#{@username_change_topic}_#{identifier}"
  defp game_state_topic(identifier), do: "#{@game_state_topic}_#{identifier}"
end
