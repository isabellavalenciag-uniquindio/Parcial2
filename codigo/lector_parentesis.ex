defmodule LectorParentesis do
  # Se numera antes de filtrar para conservar la línea física del archivo.
  # Esta función devuelve un Stream; todavía no lee todos los registros.
  def registros(ruta) do
    ruta
    |> File.stream!()
    |> Stream.with_index(1)
    |> Stream.map(fn {texto, linea} -> {linea, String.trim(texto)} end)
    |> Stream.reject(fn {_linea, texto} -> texto == "" or String.starts_with?(texto, "#") end)
    |> Stream.map(fn {linea, texto} -> {linea, limpiar_campos(String.split(texto, ";"))} end)
  end

  defp limpiar_campos([]), do: []

  defp limpiar_campos([campo | resto]) do
    [String.trim(campo) | limpiar_campos(resto)]
  end
end
