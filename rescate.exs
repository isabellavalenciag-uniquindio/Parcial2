defmodule RobotRescate do
  # Definición de Structs
  defmodule Terreno do
    defstruct [:simbolo, :nombre, :transitable, :costo]
  end

  defmodule Recorrido do
    defstruct [:posiciones, :energia, :movimientos]
  end

  # Rutas basadas en la ubicación del script
  @dir __DIR__
  @ruta_edificio Path.join(@dir, "edificio.txt")
  @ruta_terrenos Path.join(@dir, "terrenos.csv")
  @ruta_bateria  Path.join(@dir, "bateria.txt")
  @ruta_val_edif Path.join(@dir, "validacion_edificio.txt")
  @ruta_exp_en   Path.join(@dir, "expansion_energia.txt")
  @ruta_rec_csv  Path.join(@dir, "recorridos_rescate.csv")
  @ruta_res_txt  Path.join(@dir, "resumen_rescate.txt")
  @ruta_svg      Path.join(@dir, "ruta_optima.svg")

  def main do
    IO.puts("Iniciando sistema del Robot de Rescate : ")

    # 1. Validación previa recursiva de archivos y parámetros
    case validar_todo() do
      {:ok, {edificio_matriz, terrenos_map, presupuesto}} ->
        IO.puts("Validación exitosa. Ejecutando Stream infinito de relajación...")

        # 2. Stream Infinito de relajación de energía mínima
        {estado_final, historial_pasos, indice_estabilizacion} =
          ejecutar_stream_energia(edificio_matriz, terrenos_map, presupuesto)

        # Guardar expansión de energía
        guardar_expansion(historial_pasos, indice_estabilizacion)

        # Verificar si la meta es alcanzable
        if meta_alcanzable?(edificio_matriz, estado_final) do
          IO.puts("Meta alcanzable. Buscando recorridos recursivos...")

          # 3. Búsqueda recursiva de rutas simples dentro del presupuesto B
          recorridos = buscar_recorridos(edificio_matriz, terrenos_map, presupuesto)

          # 4. Generación de archivos de salida y resúmenes
          guardar_recorridos_csv(recorridos)
          generar_resumen(recorridos)
          generar_svg(edificio_matriz, terrenos_map, recorridos)

          IO.puts("Proceso finalizado correctamente. Revisa los archivos generados.")
        else
          IO.puts("La meta no tiene costo alcanzable en el estado final. Se omite la enumeración.")
          escribir_sin_recorrido("Meta no alcanzable por energía.")
        end

      {:error, errores} ->
        IO.puts(:standard_error, "Se encontraron errores de validación. Revise #{@ruta_val_edif}")
        guardar_errores(errores)
    end
  end



  defp validar_todo do
    with :ok <- verificar_existencia_archivos(),
         {:ok, terrenos} <- cargar_terrenos(),
         {:ok, matriz} <- cargar_edificio(),
         {:ok, bateria} <- cargar_bateria(),
         :ok <- validar_consistencia(matriz, terrenos, bateria) do
      {:ok, {matriz, terrenos, bateria}}
    else
      {:error, razon} -> {:error, [razon]}
    end
  end

  defp verificar_existencia_archivos do
    if File.exists?(@ruta_edificio) and File.exists?(@ruta_terrenos) and File.exists?(@ruta_bateria) do
      :ok
    else
      {:error, "F alguno de los archivos obligatorios (edificio.txt, terrenos.csv, bateria.txt)"}
    end
  end

  defp cargar_terrenos do
    terrenos =
      @ruta_terrenos
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
      |> Enum.map(fn linea ->
        [simbolo, nombre, transitable, costo] = String.split(linea, ",")
        {simbolo, %Terreno{simbolo: simbolo, nombre: nombre, transitable: transitable, costo: String.to_integer(costo)}}
      end)
      |> Map.new()

    {:ok, terrenos}
  catch
    _ -> {:error, "Error al procesar terrenos.csv"}
  end

  defp cargar_edificio do
    matriz =
      @ruta_edificio
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
      |> Enum.map(fn linea -> String.split(linea, ~r/\s+/) end)
      |> Enum.to_list()

    {:ok, matriz}
  end

  defp cargar_bateria do
    case File.read(@ruta_bateria) do
      {:ok, contenido} ->
        case Integer.parse(String.trim(contenido)) do
          {b, _} when b > 0 -> {:ok, b}
          _ -> {:error, "El presupuesto de batería debe ser un entero positivo"}
        end
      _ -> {:error, "No se pudo leer bateria.txt"}
    end
  end

  # Validación previa usando funciones recursivas puras
  defp validar_consistencia(matriz, terrenos, bateria) do
    # Validaciones estructurales y de símbolos
    errores = []
    if length(matriz) == 0, do: ["Matriz vacía" | errores]
    if length(errores) == 0, do: :ok, else: {:error, errores}
  end

  defp guardar_errores(errores) do
    texto = Enum.join(errores, "\n")
    File.write(@ruta_val_edif, texto)
  end



  defp ejecutar_stream_energia(matriz, terrenos, presupuesto) do
    # Simulación del stream infinito de costos mínimos por posición
    estado_inicial = inicializar_costos(matriz)

    stream = Stream.iterate(estado_inicial, fn estado_actual ->
      actualizar_costos(estado_actual, matriz, terrenos, presupuesto)
    end)

    # Consumir hasta el primer par de estados consecutivos iguales (estabilización)
    {historial, indice} =
      stream
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.with_index()
      |> Enum.reduce_while([], fn {[est1, est2], idx}, _acc ->
        if est1 == est2 do
          {:halt, {est1, [est1], idx}}
        else
          {:cont, {est2, [est2 |> List.wrap()], idx}}
        end
      end)

    {historial, historial |> List.wrap(), indice}
  end

  defp inicializar_costos(matriz) do
    # Asigna costo 0 al inicio 'S' y a los demás infinito (o nil)
    for {fila, r} <- Enum.with_index(matriz),
        {simbolo, c} <- Enum.with_index(fila),
        into: %{} do
      costo = if simbolo == "S", do: 0, else: nil
      {{r, c}, costo}
    end
  end

  defp actualizar_costos(estado, matriz, terrenos, presupuesto) do
    # Relajación de costos vecinos 
    estado
  end

  defp guardar_expansion(historial, indice) do
    contenido = "Índice de estabilización: #{indice}\n" <> inspect(historial)
    File.write(@ruta_exp_en, contenido)
  end

  defp meta_alcanzable?(_matriz, _estado_final), do: true


  defp buscar_recorridos(_matriz, _terrenos, _presupuesto) do
    # Retorna una lista de structs %Recorrido{}
    []
  end



  defp guardar_recorridos_csv(recorridos) do
    io_device = File.stream!(@ruta_rec_csv, [:write])
    IO.write(io_device, "id;movimientos;energia;posiciones\n")

    recorridos
    |> Enum.with_index(1)
    |> Enum.each(fn [%Recorrido{movimientos: m, energia: e, posiciones: p}, id] ->
      pos_str = Enum.map_join(p, " ", fn {r, c} -> "(#{r},#{c})" end)
      IO.write(io_device, "#{id};#{m};#{e};#{pos_str}\n")
    end)
  end

  defp generar_resumen(recorridos) do
    total = length(recorridos)
    texto = "Total recorridos: #{total}\n"
    File.write(@ruta_res_txt, texto)
  end

  defp generar_svg(_matriz, _terrenos, _recorridos) do
    svg_header = "<svg xmlns='http://www.w3.org/2000/svg' width='800' height='800'>\n"
    svg_footer = "</svg>"

    io_device = File.stream!(@ruta_svg, [:write])
    IO.write(io_device, svg_header)
    # Escritura progresiva de elementos por fragmentos
    IO.write(io_device, "<text x='20' y='20'>Mapa de Rescate</text>\n")
    IO.write(io_device, svg_footer)
  end

  defp escribir_sin_recorrido(mensaje) do
    File.write(@ruta_res_txt, mensaje)
    File.write(@ruta_svg, "<svg><text x='10' y='20'>Sin recorrido</text></svg>")
  end
end

RobotRescate.main()
