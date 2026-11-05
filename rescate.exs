for archivo <- ~w(terreno recorrido lector validador relajacion buscador escritor) do
  Code.require_file(Path.join([__DIR__, "codigo", archivo <> ".ex"]))
end

defmodule Rescate do
  def main(args) do
    carpeta =
      case args do
        [c | _] -> Path.expand(c)
        [] -> Path.join([__DIR__, "datos", "valido"])
      end

    salida = Path.join([__DIR__, "salida", Path.basename(carpeta)])

    rutas = %{
      edificio: Path.join(carpeta, "edificio.txt"),
      terrenos: Path.join(carpeta, "terrenos.csv"),
      bateria: Path.join(carpeta, "bateria.txt")
    }

    case rutas |> Map.values() |> Enum.reject(&File.exists?/1) do
      [] ->
        ejecutar(rutas, salida)

      faltantes ->
        Enum.each(faltantes, fn ruta ->
          IO.puts(:standard_error, "Aviso: no existe el archivo requerido #{ruta}")
        end)
    end
  end

  defp ejecutar(rutas, salida) do
    File.mkdir_p!(salida)

    filas = Lector.edificio(rutas.edificio)
    registros = Lector.terrenos(rutas.terrenos)
    lineas_bateria = Lector.bateria(rutas.bateria)

    errores =
      Validador.terrenos(registros) ++
        Validador.edificio(filas, Validador.simbolos(registros)) ++
        Validador.bateria(lineas_bateria)

    Escritor.validacion(Path.join(salida, "validacion_edificio.txt"), errores)

    case errores do
      [] ->
        buscar(filas, registros, lineas_bateria, salida)

      _ ->
        IO.puts(
          "Se encontraron #{length(errores)} error(es). Revise validacion_edificio.txt. " <>
            "No se inicia la búsqueda."
        )
    end
  end

  defp buscar(filas, registros, lineas_bateria, salida) do
    terrenos = Lector.construir_terrenos(registros)
    grilla = Lector.construir_grilla(filas)
    b = Lector.construir_bateria(lineas_bateria)
    inicio = posicion(grilla, "S")
    meta = posicion(grilla, "M")
    nf = length(filas)
    nc = filas |> hd() |> elem(1) |> length()

    # Stream infinito de relajación (filtro previo)
    {pasos, indice} =
      grilla
      |> Relajacion.stream(terrenos, b, inicio)
      |> Relajacion.estabilizar()

    Relajacion.escribir(Path.join(salida, "expansion_energia.txt"), pasos, indice)

    recorridos =
      if Map.has_key?(List.last(pasos), meta) do
        Buscador.buscar(grilla, terrenos, inicio, meta, b)
      else
        IO.puts("La meta no es alcanzable con B=#{b}: se omite la enumeración recursiva.")
        []
      end

    indexados = recorridos |> Enum.with_index(1) |> Enum.map(fn {r, i} -> {i, r} end)

    optima =
      case indexados do
        [] -> nil
        _ -> indexados |> Enum.min_by(fn {_id, r} -> r.energia end) |> elem(1)
      end

    Escritor.csv(Path.join(salida, "recorridos_rescate.csv"), indexados)

    lineas = Escritor.resumen_lineas(indexados)
    Escritor.resumen(Path.join(salida, "resumen_rescate.txt"), lineas)
    Enum.each(lineas, &IO.write/1)

    Escritor.svg(Path.join(salida, "ruta_optima.svg"), grilla, terrenos, nf, nc, inicio, meta, optima)

    IO.puts("\nArchivos generados en #{salida}")
  end

  defp posicion(grilla, simbolo) do
    {pos, _} = Enum.find(grilla, fn {_pos, s} -> s == simbolo end)
    pos
  end
end

Rescate.main(System.argv())
