defmodule Msiysp.Format do
  defp pad2digit(int), do: String.pad_leading(Integer.to_string(int), 2, "0")

  def time(seconds) when is_nil(seconds), do: "N/A"

  def time(seconds) do
    hours = trunc(seconds / 3600)
    minutes = trunc(rem(trunc(seconds), 3600) / 60)
    secs = rem(trunc(seconds), 60)

    if hours > 0 do
      "#{hours}:#{pad2digit(minutes)}:#{pad2digit(secs)}"
    else
      "#{minutes}:#{pad2digit(secs)}"
    end
  end
end
