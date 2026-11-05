Code.require_file("codigo/lector_parentesis.ex", __DIR__)
Code.require_file("codigo/validador_parentesis.ex", __DIR__)
Code.require_file("codigo/generador_parentesis.ex", __DIR__)
Code.require_file("codigo/escritor_parentesis.ex", __DIR__)

defmodule Parentesis do
  def main(argumentos) do
    case argumentos do
      [] -> ejecutar(Path.join([__DIR__, "datos", "valido"]))
      [carpeta] -> ejecutar(Path.expand(carpeta))
      _ -> IO.puts(:standard_error, "Uso: elixir parentesis.exs [carpeta_de_datos]")
    end
  end

  defp ejecutar(carpeta) do
    parametros = Path.join(carpeta, "parametros.csv")
    propuestas = Path.join(carpeta, "propuestas.txt")
    faltantes = Enum.reject([parametros, propuestas], &File.regular?/1)

    case faltantes do
      [] ->
        salida = Path.join([__DIR__, "salida", Path.basename(carpeta)])
        validar_archivos(parametros, propuestas, salida)

      _ ->
        Enum.each(faltantes, fn ruta ->
          IO.puts(:standard_error, "Aviso: no existe el archivo requerido #{ruta}")
        end)
    end
  end

  defp validar_archivos(parametros, propuestas, salida) do
    with :ok <- File.mkdir_p(Path.relative_to_cwd(salida)),
         {:ok, conteo_parametros} <-
           escribir_reporte(Path.join(salida, "validacion_parametros.txt"), fn archivo ->
             revisar_parametros(parametros, archivo)
           end),
         {:ok, conteo_propuestas} <-
           escribir_reporte(Path.join(salida, "verificacion_parentesis.txt"), fn archivo ->
             revisar_propuestas(propuestas, archivo)
           end),
         :ok <- generar_archivos(parametros, salida, conteo_parametros) do
      IO.puts(
        "Parámetros: #{conteo_parametros.validos} válidos, #{conteo_parametros.invalidos} inválidos."
      )

      IO.puts(
        "Propuestas: #{conteo_propuestas.validos} válidas, #{conteo_propuestas.invalidos} inválidas."
      )

      IO.puts("Archivos guardados en #{salida}")
    else
      {:error, motivo} ->
        IO.puts(
          :standard_error,
          "No fue posible crear los archivos de salida: #{:file.format_error(motivo)}"
        )
    end
  end

  defp generar_archivos(_parametros, _salida, %{invalidos: invalidos}) when invalidos > 0 do
    IO.puts("No se generan soluciones: corrija los errores de validacion_parametros.txt.")
    :ok
  end

  defp generar_archivos(parametros, salida, _conteo) do
    parametros
    |> LectorParentesis.registros()
    |> Enum.reduce_while(:ok, fn {_linea, campos}, :ok ->
      case ValidadorParentesis.parametros(campos) do
        {:ok, {n, p}} ->
          ruta = Path.join(salida, "parentesis_n#{n}_p#{p}.txt")

          case EscritorParentesis.soluciones(ruta, GeneradorParentesis.generar(n, p)) do
            {:ok, total} ->
              IO.puts("n=#{n}, p=#{p}: Total: #{total}")
              {:cont, :ok}

            {:error, motivo} ->
              {:halt, {:error, motivo}}
          end

        {:error, _errores} ->
          IO.puts("Los parámetros cambiaron durante la ejecución; vuelva a ejecutar el programa.")
          {:halt, :ok}
      end
    end)
  end

  defp escribir_reporte(ruta, escribir) do
    case File.open(ruta, [:write, :utf8]) do
      {:ok, archivo} ->
        try do
          {:ok, escribir.(archivo)}
        after
          File.close(archivo)
        end

      {:error, motivo} ->
        {:error, motivo}
    end
  end

  defp revisar_parametros(ruta, archivo) do
    ruta
    |> LectorParentesis.registros()
    |> Enum.reduce(%{validos: 0, invalidos: 0}, fn {linea, campos}, conteo ->
      case ValidadorParentesis.parametros(campos) do
        {:ok, {n, p}} ->
          IO.puts(archivo, "parametros.csv línea #{linea}: VÁLIDO (n=#{n}, p=#{p})")
          %{conteo | validos: conteo.validos + 1}

        {:error, errores} ->
          IO.puts(archivo, "parametros.csv línea #{linea}: INVÁLIDO")
          Enum.each(errores, &IO.puts(archivo, "  - #{&1}"))
          %{conteo | invalidos: conteo.invalidos + 1}
      end
    end)
    |> escribir_totales(archivo)
  end

  defp revisar_propuestas(ruta, archivo) do
    ruta
    |> LectorParentesis.registros()
    |> Enum.reduce(%{validos: 0, invalidos: 0}, fn {linea, campos}, conteo ->
      resultado = ValidadorParentesis.propuesta(campos)
      estado = if resultado.valida, do: "VÁLIDA", else: "INVÁLIDA"
      IO.puts(archivo, "propuestas.txt línea #{linea}: #{estado}")

      if resultado.cadena != nil do
        IO.puts(archivo, "  Cadena: #{inspect(resultado.cadena)}")
        IO.puts(archivo, "  Profundidad máxima alcanzada: #{resultado.profundidad}")
      end

      Enum.each(resultado.errores, &IO.puts(archivo, "  - #{&1}"))

      if resultado.valida,
        do: %{conteo | validos: conteo.validos + 1},
        else: %{conteo | invalidos: conteo.invalidos + 1}
    end)
    |> escribir_totales(archivo)
  end

  defp escribir_totales(conteo, archivo) do
    IO.puts(archivo, "Total válidos: #{conteo.validos}; total inválidos: #{conteo.invalidos}")
    conteo
  end
end

Parentesis.main(System.argv())
