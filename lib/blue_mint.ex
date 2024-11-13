defmodule BlueMint do
  @lobby_messages_topic "lobby_messages_"
  @user_messages_topic "user_messages_"
  @username_change_topic "username_change_"
  @game_state_topic "game_state_"

  def lobby_messages_topic(identifier), do: "#{@lobby_messages_topic}_#{identifier}"
  def user_messages_topic(identifier), do: "#{@user_messages_topic}_#{identifier}"
  def username_change_topic(identifier), do: "#{@username_change_topic}_#{identifier}"
  def game_state_topic(identifier), do: "#{@game_state_topic}_#{identifier}"

  def generate_unique_identifier(),
    do: :crypto.strong_rand_bytes(32) |> Base.encode64(padding: false) |> binary_part(0, 32)

  def pretty_atom(atom),
    do:
      atom
      |> Atom.to_string()
      |> String.split("_")
      |> Enum.map(fn x -> String.capitalize(x) end)
      |> Enum.join(" ")
end
