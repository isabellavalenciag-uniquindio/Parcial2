defmodule Recorrido do
  # posiciones: lista de {fila, columna} desde S hasta M
  # energia: energía total consumida
  defstruct posiciones: [], energia: 0

  def movimientos(%Recorrido{posiciones: posiciones}), do: length(posiciones) - 1
end
