defmodule Msiysp.Format do
  def time(seconds) when is_nil(seconds), do: "N/A"

  def time(seconds) do
    hours = trunc(seconds / 3600)
    minutes = trunc(rem(trunc(seconds), 3600) / 60)
    secs = rem(trunc(seconds), 60)

    if hours > 0 do
      "#{hours}:#{String.pad_leading(Integer.to_string(minutes), 2, "0")}:#{String.pad_leading(Integer.to_string(secs), 2, "0")}"
    else
      "#{minutes}:#{String.pad_leading(Integer.to_string(secs), 2, "0")}"
    end
  end
end
