defmodule ExpunjiWeb.ErrorView do
  use Phoenix.View, root: "lib/expunji_web/templates", namespace: ExpunjiWeb
  use Phoenix.HTML

  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
