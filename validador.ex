defmodule Validador do
  # Validación previa con funciones RECURSIVAS propias.
  # Cada función devuelve una lista de mensajes de error ([] si todo está bien)

  # Auxiliares recursivas

  defp contiene?([], _), do: false
  defp contiene?([x | _], x), do: true
  defp contiene?([_ | resto], x), do: contiene?(resto, x)

  # Símbolos definidos en la tabla de terrenos
  def simbolos([]), do: []
  def simbolos([{_n, [simbolo | _]} | resto]), do: [simbolo | simbolos(resto)]

  # bateria.txt

  def bateria([]), do: ["bateria.txt: no contiene ningún valor"]

  def bateria([{n, texto}]) do
    case Integer.parse(texto) do
      {b, ""} when b > 0 -> []
      _ -> ["bateria.txt línea #{n}: '#{texto}' no es un entero positivo"]
    end
  end

  def bateria([_ | _] = lineas),
    do: ["bateria.txt: se esperaba un único valor y hay #{length(lineas)}"]

  # terrenos.csv

  def terrenos(registros), do: terrenos(registros, [], [])

  defp terrenos([], _vistos, errores), do: errores

  defp terrenos([{n, [simbolo, _nombre, transitable, costo]} | resto], vistos, errores) do
    nuevos =
      validar_repetido(n, simbolo, vistos) ++
        validar_transitable(n, transitable) ++
        validar_costo(n, simbolo, transitable, costo)

    terrenos(resto, [simbolo | vistos], errores ++ nuevos)
  end

  defp terrenos([{n, campos} | resto], vistos, errores) do
    mensaje = "terrenos.csv línea #{n}: se esperaban 4 campos y hay #{length(campos)}"
    terrenos(resto, vistos, errores ++ [mensaje])
  end

  defp validar_repetido(n, simbolo, vistos) do
    if contiene?(vistos, simbolo),
      do: ["terrenos.csv línea #{n}: símbolo repetido '#{simbolo}'"],
      else: []
  end

  defp validar_transitable(_n, "si"), do: []
  defp validar_transitable(_n, "no"), do: []

  defp validar_transitable(n, otro),
    do: ["terrenos.csv línea #{n}: transitable debe ser 'si' o 'no' y es '#{otro}'"]

  defp validar_costo(n, simbolo, transitable, texto) do
    case Integer.parse(texto) do
      {c, ""} when c >= 0 -> validar_costo_positivo(n, simbolo, transitable, c)
      _ -> ["terrenos.csv línea #{n}: el costo '#{texto}' no es un entero no negativo"]
    end
  end

  defp validar_costo_positivo(n, simbolo, "si", 0) when simbolo != "S",
    do: ["terrenos.csv línea #{n}: la casilla transitable '#{simbolo}' debe tener costo positivo"]

  defp validar_costo_positivo(_n, _simbolo, _transitable, _c), do: []

  # edificio.txt

  def edificio([], _definidos), do: ["edificio.txt: la cuadrícula está vacía"]

  def edificio([{_n, primera} | _] = filas, definidos) do
    ancho = length(primera)
    acc = %{errores: [], s: 0, m: 0}
    %{errores: errores, s: s, m: m} = filas_celdas(filas, 0, length(filas), definidos, acc)

    rectangular(filas, ancho) ++ errores ++ validar_conteo("S", s) ++ validar_conteo("M", m)
  end

  # Todas las filas con el mismo número de columnas
  defp rectangular([], _ancho), do: []

  defp rectangular([{n, simbolos} | resto], ancho) do
    columnas = length(simbolos)

    error =
      if columnas == ancho,
        do: [],
        else: ["edificio.txt línea #{n}: tiene #{columnas} columnas y se esperaban #{ancho}"]

    error ++ rectangular(resto, ancho)
  end

  # Recorre filas y luego columnas validando símbolos, conteo de S/M y borde
  defp filas_celdas([], _f, _nf, _definidos, acc), do: acc

  defp filas_celdas([{_n, simbolos} | resto], f, nf, definidos, acc) do
    acc = columnas_celdas(simbolos, f, 0, nf, length(simbolos), definidos, acc)
    filas_celdas(resto, f + 1, nf, definidos, acc)
  end

  defp columnas_celdas([], _f, _c, _nf, _nc, _definidos, acc), do: acc

  defp columnas_celdas([simbolo | resto], f, c, nf, nc, definidos, acc) do
    acc =
      acc
      |> validar_definido(simbolo, f, c, definidos)
      |> contar(simbolo)
      |> validar_borde(simbolo, f, c, nf, nc)

    columnas_celdas(resto, f, c + 1, nf, nc, definidos, acc)
  end

  defp agregar(acc, mensaje), do: %{acc | errores: acc.errores ++ [mensaje]}

  defp validar_definido(acc, simbolo, f, c, definidos) do
    if contiene?(definidos, simbolo),
      do: acc,
      else: agregar(acc, "Coordenada {#{f},#{c}}: el símbolo '#{simbolo}' no está en terrenos.csv")
  end

  defp contar(acc, "S"), do: %{acc | s: acc.s + 1}
  defp contar(acc, "M"), do: %{acc | m: acc.m + 1}
  defp contar(acc, _), do: acc

  defp validar_borde(acc, simbolo, f, c, nf, nc)
       when f == 0 or f == nf - 1 or c == 0 or c == nc - 1 do
    if simbolo == "X",
      do: acc,
      else: agregar(acc, "Coordenada {#{f},#{c}}: el borde debe ser 'X' y es '#{simbolo}'")
  end

  defp validar_borde(acc, _simbolo, _f, _c, _nf, _nc), do: acc

  defp validar_conteo(_letra, 1), do: []

  defp validar_conteo(letra, cantidad),
    do: ["edificio.txt: debe haber exactamente un '#{letra}' y hay #{cantidad}"]
end
