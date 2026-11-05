defmodule ValidadorParentesis do
  # Las validaciones de este módulo no utilizan Enum ni Stream.
  def parametros([texto_n, texto_p]) do
    {n, p, errores} = validar_numeros(texto_n, texto_p)

    case errores do
      [] -> {:ok, {n, p}}
      _ -> {:error, errores}
    end
  end

  def parametros(_campos), do: {:error, ["se esperaban dos campos: n;p"]}

  def propuesta([texto_n, texto_p, cadena]) do
    {n, p, errores_numeros} = validar_numeros(texto_n, texto_p)

    estado = %{
      longitud: 0,
      balance: 0,
      profundidad: 0,
      primer_cierre_invalido: nil,
      primer_exceso: nil,
      caracteres_invalidos: []
    }

    resultado = recorrer(cadena, p, estado)

    errores =
      errores_numeros ++
        error_longitud(n, resultado.longitud) ++
        invertir(resultado.caracteres_invalidos, []) ++
        error_cierre(resultado.primer_cierre_invalido, cadena) ++
        error_balance(resultado.balance) ++
        error_profundidad(p, resultado, cadena)

    %{
      valida: errores == [],
      cadena: cadena,
      profundidad: resultado.profundidad,
      errores: errores
    }
  end

  def propuesta(_campos) do
    %{
      valida: false,
      cadena: nil,
      profundidad: nil,
      errores: ["se esperaban tres campos: n;p;cadena"]
    }
  end

  defp validar_numeros(texto_n, texto_p) do
    {n, errores_n} = entero_positivo(texto_n, "n")
    {p, errores_p} = entero_positivo(texto_p, "p")
    {n, p, errores_n ++ errores_p ++ error_rango(n, p)}
  end

  defp entero_positivo(texto, nombre) do
    case Integer.parse(texto) do
      {valor, ""} when valor >= 1 -> {valor, []}
      _ -> {nil, ["#{nombre} debe ser un entero mayor o igual a 1; se recibió #{inspect(texto)}"]}
    end
  end

  defp error_rango(n, p) when is_integer(n) and is_integer(p) and p > n,
    do: ["p no puede superar n: n=#{n}, p=#{p}"]

  defp error_rango(_n, _p), do: []

  # Caso base: no quedan caracteres. Cada llamada consume un carácter.
  defp recorrer("", _p, estado), do: estado

  defp recorrer(cadena, p, estado) do
    {caracter, resto} = String.next_codepoint(cadena)
    posicion = estado.longitud + 1
    actualizado = actualizar(caracter, posicion, estado)
    profundidad = max(actualizado.profundidad, actualizado.balance)

    primer_cierre =
      if actualizado.balance < 0 and actualizado.primer_cierre_invalido == nil,
        do: posicion,
        else: actualizado.primer_cierre_invalido

    primer_exceso =
      if is_integer(p) and actualizado.balance > p and actualizado.primer_exceso == nil,
        do: posicion,
        else: actualizado.primer_exceso

    recorrer(resto, p, %{
      actualizado
      | longitud: posicion,
        profundidad: profundidad,
        primer_cierre_invalido: primer_cierre,
        primer_exceso: primer_exceso
    })
  end

  defp actualizar("(", _posicion, estado), do: %{estado | balance: estado.balance + 1}
  defp actualizar(")", _posicion, estado), do: %{estado | balance: estado.balance - 1}

  defp actualizar(caracter, posicion, estado) do
    error = "carácter no permitido #{inspect(caracter)} en posición #{posicion}"
    %{estado | caracteres_invalidos: [error | estado.caracteres_invalidos]}
  end

  defp error_longitud(n, longitud) when is_integer(n) and longitud != 2 * n,
    do: ["longitud incorrecta: se esperaban #{2 * n} caracteres y hay #{longitud}"]

  defp error_longitud(_n, _longitud), do: []

  defp error_cierre(nil, _cadena), do: []

  defp error_cierre(posicion, cadena) do
    prefijo = String.slice(cadena, 0, posicion)

    [
      "cierre sin apertura: primer prefijo problemático #{inspect(prefijo)} (posición #{posicion})"
    ]
  end

  defp error_balance(0), do: []
  defp error_balance(balance), do: ["balance final distinto de cero: #{balance}"]

  defp error_profundidad(p, estado, cadena)
       when is_integer(p) and estado.profundidad > p do
    prefijo = String.slice(cadena, 0, estado.primer_exceso)

    [
      "profundidad máxima alcanzada #{estado.profundidad}, superior a p=#{p}; " <>
        "primer prefijo problemático #{inspect(prefijo)} (posición #{estado.primer_exceso})"
    ]
  end

  defp error_profundidad(_p, _estado, _cadena), do: []

  defp invertir([], acumulado), do: acumulado
  defp invertir([primero | resto], acumulado), do: invertir(resto, [primero | acumulado])
end
