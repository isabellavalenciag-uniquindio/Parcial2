Code.require_file("../codigo/generador_parentesis.ex", __DIR__)
Code.require_file("../codigo/secuencia_parentesis.ex", __DIR__)
Code.require_file("../codigo/escritor_parentesis.ex", __DIR__)

ExUnit.start()

defmodule StreamsParentesisTest do
  use ExUnit.Case

  test "el Stream infinito permite consumir únicamente un prefijo de los totales" do
    assert SecuenciaParentesis.stream() |> Enum.take(4) == [{1, 1}, {2, 2}, {3, 5}, {4, 14}]
  end

  @tag timeout: 2_000
  test "el archivo del caso grande contiene solo la primera solución y no pide una segunda" do
    ruta = ruta_temporal("primera")
    primera = String.duplicate("(", 18) <> String.duplicate(")", 18)

    stream =
      GeneradorParentesis.generar(18, 18)
      |> Stream.with_index()
      |> Stream.map(fn {cadena, indice} ->
        assert indice == 0, "se consumió una segunda solución"
        cadena
      end)

    assert {:ok, :ok} = EscritorParentesis.primera(ruta, stream)
    assert File.read!(ruta) == primera <> "\n"
  end

  test "el CSV incluye n=8 y el consumo se detiene antes de pedir n=9" do
    ruta = ruta_temporal("secuencia")

    stream =
      SecuenciaParentesis.stream()
      |> Stream.map(fn {n, _total} = registro ->
        send(self(), {:total_calculado, n})
        assert n <= 8, "se calculó n=9 después de alcanzar el umbral"
        registro
      end)

    assert {:ok, {8, 1430}} = EscritorParentesis.secuencia(ruta, stream)

    assert File.read!(ruta) ==
             "n;total\n1;1\n2;2\n3;5\n4;14\n5;42\n6;132\n7;429\n8;1430\n"

    for n <- 1..8 do
      assert_received {:total_calculado, ^n}
    end

    refute_received {:total_calculado, 9}
  end

  test "si el primer total es igual al umbral se escribe y se detiene inmediatamente" do
    ruta = ruta_temporal("umbral")

    stream =
      Stream.concat(
        [{1, 1}],
        Stream.map([:sobrante], fn _ -> flunk("consumo posterior al umbral") end)
      )

    assert {:ok, {1, 1}} = EscritorParentesis.secuencia(ruta, stream, 1)
    assert File.read!(ruta) == "n;total\n1;1\n"
  end

  test "los escritores informan cuando no pueden abrir el archivo" do
    ruta =
      Path.join([
        __DIR__,
        "carpeta_inexistente_#{System.unique_integer([:positive])}",
        "salida.txt"
      ])

    assert {:error, :enoent} =
             EscritorParentesis.primera(ruta, GeneradorParentesis.generar(18, 18))

    assert {:error, :enoent} = EscritorParentesis.secuencia(ruta, SecuenciaParentesis.stream())
  end

  defp ruta_temporal(nombre) do
    ruta = Path.join(__DIR__, "#{nombre}_temporal_#{System.unique_integer([:positive])}.txt")
    on_exit(fn -> File.rm(ruta) end)
    ruta
  end
end
