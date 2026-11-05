Code.require_file("../codigo/generador_parentesis.ex", __DIR__)
Code.require_file("../codigo/escritor_parentesis.ex", __DIR__)
Code.require_file("../codigo/validador_parentesis.ex", __DIR__)

ExUnit.start()

defmodule GeneradorParentesisTest do
  use ExUnit.Case
  import Bitwise

  test "produce exactamente las cuatro soluciones del PDF en el orden requerido" do
    assert Enum.to_list(GeneradorParentesis.generar(3, 2)) == [
             "(()())",
             "(())()",
             "()(())",
             "()()()"
           ]
  end

  test "los totales sin restricción coinciden con los casos conocidos" do
    for {n, esperado} <- [{1, 1}, {2, 2}, {3, 5}, {4, 14}, {5, 42}, {8, 1430}] do
      assert Enum.count(GeneradorParentesis.generar(n, n)) == esperado
    end
  end

  test "con profundidad uno solo se permite alternar apertura y cierre" do
    for n <- 1..6 do
      assert Enum.to_list(GeneradorParentesis.generar(n, 1)) == [String.duplicate("()", n)]
    end
  end

  test "no omite ni repite soluciones al comparar con todas las cadenas pequeñas" do
    for n <- 1..4, p <- 1..n do
      # Referencia independiente: construir todas las combinaciones de '(' y ')'
      # de longitud 2n y conservar las aceptadas por el validador recursivo.
      esperadas =
        0..(Integer.pow(2, 2 * n) - 1)
        |> Enum.map(fn bits ->
          for indice <- (2 * n - 1)..0//-1, into: "" do
            if (bits >>> indice &&& 1) == 0, do: "(", else: ")"
          end
        end)
        |> Enum.filter(fn cadena ->
          ValidadorParentesis.propuesta([Integer.to_string(n), Integer.to_string(p), cadena]).valida
        end)

      assert Enum.to_list(GeneradorParentesis.generar(n, p)) == esperadas
    end
  end

  @tag timeout: 2_000
  test "permite tomar solo la primera solución de un caso grande" do
    stream = GeneradorParentesis.generar(18, 18)
    assert Enum.take(stream, 1) == [String.duplicate("(", 18) <> String.duplicate(")", 18)]
  end

  test "rechaza parámetros fuera del dominio" do
    for {n, p} <- [{0, 1}, {3, 0}, {3, 4}, {3.0, 2}, {"3", 2}] do
      assert_raise ArgumentError, fn -> GeneradorParentesis.generar(n, p) end
    end
  end

  test "escribe cada solución, agrega el total y reemplaza el contenido anterior" do
    ruta = Path.join(__DIR__, "salida_temporal_#{System.unique_integer([:positive])}.txt")
    on_exit(fn -> File.rm(ruta) end)
    File.write!(ruta, "contenido anterior\n")

    assert {:ok, 4} = EscritorParentesis.soluciones(ruta, GeneradorParentesis.generar(3, 2))
    assert File.read!(ruta) == "(()())\n(())()\n()(())\n()()()\nTotal: 4\n"
  end
end
