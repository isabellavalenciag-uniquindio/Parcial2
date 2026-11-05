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
end
