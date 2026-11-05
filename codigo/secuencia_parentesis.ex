defmodule SecuenciaParentesis do
  # La fuente es infinita: 1, 2, 3... Cada total se calcula solo cuando
  # se solicita ese elemento y se cuenta usando nuestro generador recursivo.
  def stream do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.map(fn n ->
      total = GeneradorParentesis.generar(n, n) |> Enum.count()
      {n, total}
    end)
  end
end
