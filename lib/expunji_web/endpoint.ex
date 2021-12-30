defmodule ExpunjiWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :expunji

  plug(ExpunjiWeb.MetricsExporter)
  plug(ExpunjiWeb.Router)
end
