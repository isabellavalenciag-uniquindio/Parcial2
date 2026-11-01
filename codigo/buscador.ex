defmodule Buscador do
  # Enumeración recursiva de todos los recorridos simples S -> M
  # que no superan la batería B. Orden fijo: arriba, derecha, abajo, izquierda.

  @movimientos [{-1, 0}, {0, 1}, {1, 0}, {0, -1}]

  def buscar(grilla, terrenos, inicio, meta, b) do
    contexto = %{grilla: grilla, terrenos: terrenos, meta: meta, b: b}
    explorar(inicio, contexto, [inicio], 0)
  end

  # Prueba los cuatro movimientos desde pos
  defp explorar(pos, contexto, camino, energia) do
    avanzar(@movimientos, pos, contexto, camino, energia)
  end

  defp avanzar([], _pos, _contexto, _camino, _energia), do: []

  defp avanzar([{df, dc} | resto], {f, c} = pos, contexto, camino, energia) do
    encontrados = intentar({f + df, c + dc}, contexto, camino, energia)
    encontrados ++ avanzar(resto, pos, contexto, camino, energia)
  end

  defp intentar(destino, contexto, camino, energia) do
    with {:ok, simbolo} <- Map.fetch(contexto.grilla, destino),
         # pattern matching: rechaza terrenos no transitables
         %Terreno{transitable: true, costo: costo} <- Map.fetch!(contexto.terrenos, simbolo),
         false <- destino in camino,
         nueva = energia + costo,
         true <- nueva <= contexto.b do
      if destino == contexto.meta do
        [%Recorrido{posiciones: Enum.reverse([destino | camino]), energia: nueva}]
      else
        explorar(destino, contexto, [destino | camino], nueva)
      end
    else
      _ -> []
    end
  end
end
