defmodule ConsoleWeb.Live.Index do
  use ConsoleWeb, :live_view

  defmodule User do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field(:name, :string)
      field(:email, :string)
    end

    def changeset(attrs \\ %{}, user \\ %User{}) do
      user
      |> cast(attrs, User.__schema__(:fields))
      |> validate_required([:name, :email])
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(users: [])}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: :create}} = socket) do
    {:noreply,
     socket
     |> assign(
       form: to_form(params),
       valid_form: false,
       blocked_form: false,
       valid_email: nil
     )}
  end

  @impl true
  def handle_params(%{"id" => id} = _params, _url, %{assigns: %{live_action: :update}} = socket) do
    editable_user =
      socket.assigns.users
      |> Enum.find(&(Integer.to_string(&1.id) == id))

    socket =
      if is_nil(editable_user) do
        socket
        |> put_flash(:error, "Usuário a atualizar não foi encontrado")
        |> push_patch(
          to: "/",
          replace: true
        )
      else
        socket
        |> assign(:editable_user, editable_user)
        |> assign(:valid_form, true)
        |> assign(:form, editable_user |> Map.from_struct() |> convert_map_atoms_to_keys() |> to_form())
      end

    {:noreply,
      socket
    }
  end

  @impl true
  def handle_params(_params, _url, %{assigns: %{live_action: :update}} = socket) do
    {:noreply, socket |> assign(:editable_user, nil)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def handle_info({:validate_email, value}, socket) do
    form =
      socket.assigns.form
      |> Map.put("email", value)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:valid_form, Enum.empty?(form.errors))
     |> assign(:blocked_form, false)
    }
  end

  @impl true
  def handle_event("validate_new_user", %{"_target" => ["email"]} = params, socket) do
    form = validate_creation_form(params)

    {:noreply,
      socket
      |> assign(:form, form)
    }
  end

  @impl true
  def handle_event("validate_email", %{"key" => key, "value" => value} = params, socket) when key in ["Tab"] do
    Process.send_after(self(), {:validate_email, params}, 2000)

    {:noreply, socket |> assign(:blocked_form, true)}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_new_user", params, socket) do
    form =
      params
      |> validate_creation_form()

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:valid_form, Enum.empty?(form.errors))}
  end

  @impl true
  def handle_event("validate_user_update", params, socket) do
    form = validate_update_form(socket.assigns.editable_user, params)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:valid_form, Enum.empty?(form.errors))}
  end

  @impl true
  def handle_event("create", params, socket) do
    new_user_id =
      socket.assigns
      |> Map.get(:users)
      |> length()
      |> Kernel.+(1)

    user =
      params
      |> convert_map_keys_to_atoms()
      |> Map.put(:id, new_user_id)
      |> create_user()

    {:noreply,
     socket
     |> assign(:users, Enum.concat(socket.assigns.users, [user]))
     |> assign(:form, to_form(%{}))
    }
  end

  @impl true
  def handle_event("update", params, socket) do
    updated_user =
      params
      |> convert_map_keys_to_atoms()
      |> update_existing_user(socket.assigns.editable_user)

    users =
      socket.assigns.users
      |> Enum.filter(fn user ->
        user.id != socket.assigns.editable_user.id
      end)
      |> Enum.concat([updated_user |> Map.put(:id, socket.assigns.editable_user.id)])
      |> Enum.sort_by(&(&1.id))

    {:noreply, socket |> assign(:users, users)}
  end

  def validate_creation_form(params) do
    params
    |> Map.delete("_target")
    |> convert_map_keys_to_atoms()
    |> User.changeset()
    |> Ecto.Changeset.apply_action(:validate)
    |> case do
      {:ok, valid_params} ->
        valid_params
        |> Map.from_struct()
        |> convert_map_atoms_to_keys()
        |> to_form()

      {:error, %Ecto.Changeset{errors: errors}} ->
        to_form(params, errors: errors)
    end
  end

  def validate_update_form(user, params) do
    params
    |> convert_map_keys_to_atoms()
    |> User.changeset(user)
    |> Ecto.Changeset.apply_action(:validate)
    |> case do
      {:ok, valid_params} ->
        valid_params
        |> Map.from_struct()
        |> convert_map_atoms_to_keys()
        |> to_form()

      {:error, %Ecto.Changeset{errors: errors}} ->
        to_form(params, errors: errors)
    end
  end

  def create_user(params), do: struct(User, params)

  def update_existing_user(params, %User{} = user) do
    %{
      id: user.id,
      name: params.name,
      email: params.email
    }
  end

  def convert_map_keys_to_atoms(string_key_map) when is_map(string_key_map) do
    for {key, val} <- string_key_map,
        into: %{},
        do: {String.to_atom(key), val}
  end

  def convert_map_atoms_to_keys(atom_key_map) when is_map(atom_key_map) do
    for {key, val} <- atom_key_map,
        into: %{},
        do: {Atom.to_string(key), val}
  end
end
