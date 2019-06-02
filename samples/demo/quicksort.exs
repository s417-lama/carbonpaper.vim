defmodule Quicksort do
  def sort([]            ), do: []
  def sort([pivot | rest]) do
    {smaller, greater} = Enum.split_with(rest, &(&1 < pivot))
    sort(smaller) ++ [pivot] ++ sort(greater)
  end
end

1..1_000_000
|> Enum.shuffle()
|> Quicksort.sort()
|> IO.inspect()
