defmodule Expunji.MockFile do
  def ls!(), do: [".gitignore", "hosts"]

  def stream!(_), do: ["# Comment", "", "127.0.0.1 baddomain.com", "127.0.0.1 baddomain.org"]
end
