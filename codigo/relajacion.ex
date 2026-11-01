defmodule Relajacion do
  # Stream infinito de mapas de costo mínimo conocido por posición.
  # Paso 0: solo S con costo 0. Cada paso actualiza las casillas transitables
  # a partir de sus vecinos (costo del vecino + costo de entrada) y descarta costos > B.

  # arriba, derecha, abajo, izquierda
  @movimientos [{-1, 0}, {0, 1}, {1, 0}, {0, -1}]

  def stream(grilla, terrenos, b, inicio) do
    Stream.iterate(%{inicio => 0}, fn costos -> paso(costos, grilla, terrenos, b) end)
  end

  defp paso(costos, grilla, terrenos, b) do
    Enum.reduce(grilla, costos, fn {pos, simbolo}, acc ->
      actualizar(acc, costos, pos, Map.fetch!(terrenos, simbolo), b)
    end)
  end

  # Pattern matching: solo se actualizan terrenos transitables
  defp actualizar(acc, costos, {f, c}, %Terreno{transitable: true, costo: entrada}, b) do
    candidatos =
      Enum.flat_map(@movimientos, fn {df, dc} ->
        case Map.fetch(costos, {f + df, c + dc}) do
          {:ok, costo_vecino} -> [costo_vecino + entrada]
          :error -> []
        end
      end)

    case candidatos do
      [] ->
        acc

      _ ->
        nuevo = Enum.min(candidatos)

        if nuevo <= b,
          do: Map.update(acc, {f, c}, nuevo, fn actual -> min(actual, nuevo) end),
          else: acc
    end
  end

  defp actualizar(acc, _costos, _pos, %Terreno{}, _b), do: acc

  # Consume el stream hasta el primer par de estados consecutivos iguales.
  # Devuelve {pasos_distintos, indice}; el índice es el del primer estado que ya no cambia.
  def estabilizar(stream) do
    distintos =
      stream
      |> Stream.chunk_every(2, 1, :discard)
      |> Stream.take_while(fn [a, b] -> a != b end)
      |> Stream.map(&hd/1)
      |> Enum.to_list()

    indice = length(distintos)
    {distintos ++ [Enum.at(stream, indice)], indice}
  end

  # Escritura progresiva de expansion_energia.txt (posiciones ordenadas por fila y columna)
  def escribir(ruta, pasos, indice) do
    pasos
    |> Stream.with_index()
    |> Stream.flat_map(fn {estado, k} -> ["Paso #{k}\n" | lineas_estado(estado)] end)
    |> Stream.concat(["Índice de estabilización: #{indice}\n"])
    |> Enum.into(File.stream!(ruta, [:write]))
  end

  defp lineas_estado(estado) do
    estado
    |> Enum.sort()
    |> Enum.map(fn {{f, c}, costo} -> "  {#{f},#{c}} -> #{costo}\n" end)
  end
end
