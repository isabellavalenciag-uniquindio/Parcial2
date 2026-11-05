defmodule Lector do
  # Lectura perezosa con File.stream!/1
  def lineas_utiles(ruta) do
    ruta
    |> File.stream!()
    |> Stream.with_index(1)
    |> Stream.map(fn {linea, n} -> {n, String.trim(linea)} end)
    |> Stream.reject(fn {_n, linea} -> linea == "" or String.starts_with?(linea, "#") end)
  end

  # [{numero_linea, [simbolos]}]
  def edificio(ruta) do
    ruta
    |> lineas_utiles()
    |> Stream.map(fn {n, linea} -> {n, String.split(linea)} end)
    |> Enum.to_list()
  end

  # [{numero_linea, [campos]}]  (campos aún como texto, se validan después)
  def terrenos(ruta) do
    ruta
    |> lineas_utiles()
    |> Stream.map(fn {n, linea} ->
      {n, linea |> String.split(",") |> Enum.map(&String.trim/1)}
    end)
    |> Enum.to_list()
  end

  # [{numero_linea, texto}]
  def bateria(ruta) do
    ruta |> lineas_utiles() |> Enum.to_list()
  end

  # Conversión (solo se usa cuando la validación no encontró errores)

  def construir_terrenos(registros) do
    registros
    |> Enum.map(fn {_n, [simbolo, nombre, transitable, costo]} ->
      {simbolo,
       %Terreno{
         simbolo: simbolo,
         nombre: nombre,
         transitable: transitable == "si",
         costo: String.to_integer(costo)
       }}
    end)
    |> Map.new()
  end

  # %{{fila, columna} => simbolo}
  def construir_grilla(filas) do
    for {{_n, simbolos}, f} <- Enum.with_index(filas),
        {simbolo, c} <- Enum.with_index(simbolos),
        into: %{},
        do: {{f, c}, simbolo}
  end

  def construir_bateria([{_n, texto}]) do
    {b, ""} = Integer.parse(texto)
    b
  end
end
