defmodule BlueMint.Common.NameManager do
  use GenServer, restart: :transient
  require Logger

  def username_generate() do
    GenServer.call(:name_manager, :username)
  end

  def lobby_name_generate() do
    GenServer.call(:name_manager, :lobby_name)
  end

  def set_username(user_id, username) do
    GenServer.call(:name_manager, {:set_username, user_id, username})
  end

  def set_lobby_name(lobby_id, name) do
    GenServer.call(:name_manager, {:set_lobby_name, lobby_id, name})
  end

  def lookup_username(user_id, generate_if_not_exists? \\ true) do
    case :ets.lookup(:username_table, user_id) do
      [{^user_id, username}] ->
        username

      [] when generate_if_not_exists? ->
        case username_generate() do
          {:ok, username} ->
            set_username(user_id, username)
            username

          _ ->
            nil
        end

      [] ->
        nil
    end
  end

  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts, name: :name_manager) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _}} ->
        :ignore
    end
  end

  def init(_) do
    load_all_words()
    :ets.new(:username_table, [:set, :protected, :named_table])
    :ets.new(:lobby_name_table, [:set, :protected, :named_table])

    {:ok,
     %{
       nouns_table: Keyword.get(:ets.info(:nouns_table), :size),
       verbs_table: Keyword.get(:ets.info(:verbs_table), :size),
       adjectives_table: Keyword.get(:ets.info(:adjectives_table), :size)
     }}
  end

  def handle_call(:username, _from, state) do
    flavor_tables = [:verbs_table, :adjectives_table]

    noun_word =
      :ets.lookup(:nouns_table, Enum.random(1..Map.get(state, :nouns_table)))
      |> hd
      |> elem(1)
      |> Macro.camelize()

    flavor_word =
      flavor_tables
      |> Enum.shuffle()
      |> Enum.take(1)
      |> Enum.map(fn table ->
        :ets.lookup(table, Enum.random(1..Map.get(state, table)))
        |> hd
        |> elem(1)
        |> Macro.camelize()
      end)

    {:reply, {:ok, "#{noun_word}#{flavor_word}"}, state}
  end

  def handle_call(:lobby_name, _from, state) do
    words =
      [:nouns_table, :verbs_table, :adjectives_table]
      |> Enum.shuffle()
      |> Enum.map(fn table ->
        :ets.lookup(table, Enum.random(1..Map.get(state, table)))
        |> hd
        |> elem(1)
        |> Macro.camelize()
      end)

    {:reply, {:ok, Enum.join(words, "")}, state}
  end

  def handle_call({:set_username, user_id, username}, _from, state) do
    :ets.insert(:username_table, {user_id, username})
    {:reply, :ok, state}
  end

  def handle_call({:set_lobby_name, lobby_id, name}, _from, state) do
    :ets.insert(:lobby_name_table, {lobby_id, name})
    {:reply, :ok, state}
  end

  defp load_all_words() do
    load_words("nouns.txt", :nouns_table)
    load_words("verbs.txt", :verbs_table)
    load_words("adjectives.txt", :adjectives_table)
  end

  defp load_words(file_name, table_name) do
    :ets.new(table_name, [:set, :private, :named_table])

    Path.join([:code.priv_dir(:blue_mint), "data", file_name])
    |> File.stream!()
    |> Stream.map(&String.trim_trailing/1)
    |> Stream.with_index(1)
    |> Stream.each(fn x ->
      :ets.insert(table_name, {elem(x, 1), elem(x, 0)})
    end)
    |> Stream.run()
  end
end
