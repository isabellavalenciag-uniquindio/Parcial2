defmodule GeneradorParentesis do
  # Crear el Stream solo prepara el prefijo vacío. La búsqueda comienza
  # cuando un consumidor pide una solución.
  def generar(n, p)
      when is_integer(n) and is_integer(p) and n >= 1 and p >= 1 and p <= n do
    Stream.unfold([{"", 0, 0}], fn pendientes -> siguiente(pendientes, n, p) end)
  end

  def generar(_n, _p) do
    raise ArgumentError, "se requiere n >= 1 y 1 <= p <= n, ambos enteros"
  end

  # Sin ramas pendientes, se termina el Stream.
  defp siguiente([], _n, _p), do: nil

  # Una solución completa se entrega junto con las ramas que quedan por buscar.
  defp siguiente([{prefijo, abiertos, cerrados} | resto], n, _p)
       when abiertos == n and cerrados == n do
    {prefijo, resto}
  end

  defp siguiente([{prefijo, abiertos, cerrados} | resto], n, p) do
    # Se usa una pila: la última rama agregada es la primera en explorarse.
    # Por eso se guarda primero ')' y después '('. Solo guardamos prefijos
    # pendientes, nunca una lista de todas las soluciones.
    con_cierre =
      if cerrados < abiertos,
        do: [{prefijo <> ")", abiertos, cerrados + 1} | resto],
        else: resto

    con_apertura =
      if abiertos < n and abiertos - cerrados < p,
        do: [{prefijo <> "(", abiertos + 1, cerrados} | con_cierre],
        else: con_cierre

    siguiente(con_apertura, n, p)
  end
end
