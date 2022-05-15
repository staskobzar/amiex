defmodule AMI do
  @moduledoc """
  Asterisk Management Interface
  """
  # ch1 = %{id: :w1, start: {AMI.Client, :start_link, ['localhost', 12345]}}
  # ch2 = %{id: :w2, start: {AMI.Client, :start_link, ['localhost', 12346]}}
  # {:ok, pid}=Supervisor.start_link([ch1,ch2],strategy: :permanent)
end
