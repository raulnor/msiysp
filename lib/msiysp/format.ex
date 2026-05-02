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

  def date_range(nil, _), do: ""
  def date_range(start_iso, end_iso) do
    parse = fn iso -> String.split(iso, "-") |> Enum.map(&String.to_integer/1) end
    month = fn m -> ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec) |> Enum.at(m - 1) end
    [s_y, s_m, s_d] = parse.(start_iso)
    [e_y, e_m, e_d] = parse.(end_iso)
    if s_y == e_y do
      "#{month.(s_m)} #{s_d} - #{month.(e_m)} #{e_d}, #{e_y}"
    else
      "#{month.(s_m)} #{s_d}, #{s_y} - #{month.(e_m)} #{e_d}, #{e_y}"
    end
  end
end
