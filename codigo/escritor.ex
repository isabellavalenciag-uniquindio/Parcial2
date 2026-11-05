defmodule Escritor do

  # validacion_edificio.txt

  def validacion(ruta, []) do
    Enum.into(["Sin errores de validación\n"], File.stream!(ruta, [:write]))
  end

  def validacion(ruta, errores) do
    errores
    |> Stream.map(fn error -> error <> "\n" end)
    |> Enum.into(File.stream!(ruta, [:write]))
  end

  #  recorridos_rescate.csv

  def csv(ruta, indexados) do
    indexados
    |> Stream.map(fn {id, r} ->
      "#{id};#{Recorrido.movimientos(r)};#{r.energia};#{posiciones_texto(r)}\n"
    end)
    |> then(fn filas -> Stream.concat(["id;movimientos;energia;posiciones\n"], filas) end)
    |> Enum.into(File.stream!(ruta, [:write]))
  end

  defp posiciones_texto(%Recorrido{posiciones: posiciones}) do
    posiciones
    |> Enum.map(fn {f, c} -> "{#{f},#{c}}" end)
    |> Enum.join("->")
  end

  # resumen_rescate.txt

  def resumen_lineas([]) do
    [
      "Total de recorridos: 0\n",
      "No existe ningún recorrido válido que alcance la meta sin superar la batería.\n"
    ]
  end

  def resumen_lineas(indexados) do
    min_mov = indexados |> Enum.map(fn {_id, r} -> Recorrido.movimientos(r) end) |> Enum.min()
    min_energia = indexados |> Enum.map(fn {_id, r} -> r.energia end) |> Enum.min()

    con_menos_mov = Enum.filter(indexados, fn {_id, r} -> Recorrido.movimientos(r) == min_mov end)
    con_menos_energia = Enum.filter(indexados, fn {_id, r} -> r.energia == min_energia end)

    ["Total de recorridos: #{length(indexados)}\n", "\n"] ++
      ["Menor número de movimientos: #{min_mov}\n"] ++
      detalle(con_menos_mov) ++
      ["\n", "Menor consumo de energía: #{min_energia}\n"] ++
      detalle(con_menos_energia)
  end

  defp detalle(indexados) do
    Enum.map(indexados, fn {id, r} ->
      "  Recorrido #{id}: #{Recorrido.movimientos(r)} movimientos, energía #{r.energia}, #{posiciones_texto(r)}\n"
    end)
  end

  def resumen(ruta, lineas) do
    Enum.into(lineas, File.stream!(ruta, [:write]))
  end

  #  ruta_optima.svg

  def escapar(texto) do
    texto
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  def svg(ruta, grilla, terrenos, nf, nc, inicio, meta, optima) do
    ancho = max(nc * 40, 300)
    alto = nf * 40 + 25 + (map_size(terrenos) + 3) * 22 + 10

    [encabezado(ancho, alto)]
    |> Stream.concat(celdas(grilla, terrenos, inicio, meta))
    |> Stream.concat(segmentos(optima))
    |> Stream.concat(leyenda(terrenos, nf, inicio, meta, optima))
    |> Stream.concat(["</svg>\n"])
    |> Enum.into(File.stream!(ruta, [:write]))
  end

  defp encabezado(ancho, alto) do
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" <>
      "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"#{ancho}\" height=\"#{alto}\" " <>
      "viewBox=\"0 0 #{ancho} #{alto}\" font-family=\"sans-serif\">\n" <>
      "  <rect width=\"100%\" height=\"100%\" fill=\"#ffffff\"/>\n"
  end

  # Colores por atributos del terreno (no por símbolo): no transitable = gris,
  # transitable = tono más oscuro cuanto mayor es el costo.
  defp color(_t, pos, inicio, _meta) when pos == inicio, do: "#2ecc71"
  defp color(_t, pos, _inicio, meta) when pos == meta, do: "#e74c3c"
  defp color(%Terreno{transitable: false}, _pos, _inicio, _meta), do: "#7f8c8d"

  defp color(%Terreno{costo: costo}, _pos, _inicio, _meta),
    do: "hsl(40,70%,#{max(92 - costo * 12, 35)}%)"

  defp celdas(grilla, terrenos, inicio, meta) do
    grilla
    |> Enum.sort()
    |> Stream.map(fn {{f, c} = pos, simbolo} ->
      terreno = Map.fetch!(terrenos, simbolo)
      x = c * 40
      y = f * 40

      "  <rect x=\"#{x}\" y=\"#{y}\" width=\"40\" height=\"40\" " <>
        "fill=\"#{color(terreno, pos, inicio, meta)}\" stroke=\"#999999\"/>\n" <>
        "  <text x=\"#{x + 20}\" y=\"#{y + 26}\" font-size=\"16\" text-anchor=\"middle\" " <>
        "fill=\"#222222\">#{escapar(simbolo)}</text>\n"
    end)
  end

  defp segmentos(nil), do: []

  defp segmentos(%Recorrido{posiciones: posiciones}) do
    posiciones
    |> Stream.chunk_every(2, 1, :discard)
    |> Stream.map(fn [{f1, c1}, {f2, c2}] ->
      "  <line x1=\"#{c1 * 40 + 20}\" y1=\"#{f1 * 40 + 20}\" x2=\"#{c2 * 40 + 20}\" " <>
        "y2=\"#{f2 * 40 + 20}\" stroke=\"#1f3fff\" stroke-width=\"5\" stroke-linecap=\"round\"/>\n"
    end)
  end

  defp leyenda(terrenos, nf, inicio, meta, optima) do
    base = nf * 40 + 25

    items =
      (terrenos
       |> Map.values()
       |> Enum.sort_by(& &1.simbolo)
       |> Enum.map(fn t ->
         {color(t, :ninguna, inicio, meta), "#{t.simbolo} = #{t.nombre} (costo #{t.costo})"}
       end)) ++ [{"#2ecc71", "Inicio"}, {"#e74c3c", "Meta"}]

    cuadros =
      items
      |> Enum.with_index()
      |> Stream.map(fn {{col, texto}, i} ->
        y = base + i * 22

        "  <rect x=\"10\" y=\"#{y - 14}\" width=\"16\" height=\"16\" fill=\"#{col}\" " <>
          "stroke=\"#666666\"/>\n" <>
          "  <text x=\"34\" y=\"#{y}\" font-size=\"14\">#{escapar(texto)}</text>\n"
      end)

    Stream.concat(cuadros, [leyenda_ruta(base + length(items) * 22, optima)])
  end

  defp leyenda_ruta(y, nil) do
    "  <text x=\"10\" y=\"#{y}\" font-size=\"14\" fill=\"#c0392b\">sin recorrido</text>\n"
  end

  defp leyenda_ruta(y, %Recorrido{energia: energia}) do
    "  <line x1=\"10\" y1=\"#{y - 6}\" x2=\"26\" y2=\"#{y - 6}\" stroke=\"#1f3fff\" " <>
      "stroke-width=\"5\" stroke-linecap=\"round\"/>\n" <>
      "  <text x=\"34\" y=\"#{y}\" font-size=\"14\">" <>
      "#{escapar("Ruta de menor energía (energía #{energia})")}</text>\n"
  end
end
