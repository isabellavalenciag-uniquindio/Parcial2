defmodule EscritorParentesis do
  # File.open/3 cierra el archivo al terminar. Cada solución se escribe
  # al consumirla y el acumulador conserva únicamente el contador.
  def soluciones(ruta, stream) do
    File.open(ruta, [:write, :utf8], fn archivo ->
      total =
        Enum.reduce(stream, 0, fn cadena, contador ->
          IO.puts(archivo, cadena)
          contador + 1
        end)

      IO.puts(archivo, "Total: #{total}")
      total
    end)
  end

  # Se pide exactamente una solución. La búsqueda no se reanuda para obtener
  # una segunda cadena, aunque queden muchas ramas pendientes.
  def primera(ruta, stream) do
    File.open(ruta, [:write, :utf8], fn archivo ->
      stream
      |> Stream.take(1)
      |> Enum.each(&IO.puts(archivo, &1))
    end)
  end

  def secuencia(ruta, stream, umbral \\ 1000) when is_integer(umbral) and umbral >= 1 do
    File.open(ruta, [:write, :utf8], fn archivo ->
      IO.puts(archivo, "n;total")

      Enum.reduce_while(stream, nil, fn {n, total}, _anterior ->
        # Primero se escribe para incluir el elemento que alcanza el umbral.
        IO.puts(archivo, "#{n};#{total}")

        if total >= umbral,
          do: {:halt, {n, total}},
          else: {:cont, {n, total}}
      end)
    end)
  end
end
