Code.require_file("../codigo/lector_parentesis.ex", __DIR__)
Code.require_file("../codigo/validador_parentesis.ex", __DIR__)

ExUnit.start()

defmodule ValidadorParentesisTest do
  use ExUnit.Case

  test "acepta los extremos válidos de profundidad" do
    assert ValidadorParentesis.propuesta(["1", "1", "()"]).valida
    assert ValidadorParentesis.propuesta(["4", "1", "()()()()"]).valida
    assert ValidadorParentesis.propuesta(["4", "4", "(((())))"]).valida
  end

  test "rechaza profundidad excesiva e identifica el primer prefijo" do
    resultado = ValidadorParentesis.propuesta(["3", "2", "((()))"])
    refute resultado.valida
    assert resultado.profundidad == 3
    assert Enum.any?(resultado.errores, &String.contains?(&1, "posición 3"))
  end

  test "detecta un cierre prematuro aunque el balance final sea cero" do
    resultado = ValidadorParentesis.propuesta(["3", "2", "())(()"])
    refute resultado.valida
    assert Enum.any?(resultado.errores, &String.contains?(&1, "cierre sin apertura"))
    refute Enum.any?(resultado.errores, &String.contains?(&1, "balance final"))
  end

  test "informa simultáneamente longitud, carácter, balance y profundidad" do
    resultado = ValidadorParentesis.propuesta(["3", "1", "((a"])
    assert length(resultado.errores) == 4
    assert Enum.any?(resultado.errores, &String.contains?(&1, "longitud incorrecta"))
    assert Enum.any?(resultado.errores, &String.contains?(&1, "carácter no permitido"))
    assert Enum.any?(resultado.errores, &String.contains?(&1, "balance final"))
    assert Enum.any?(resultado.errores, &String.contains?(&1, "profundidad máxima"))
  end

  test "registra cada carácter inválido con su posición" do
    resultado = ValidadorParentesis.propuesta(["1", "1", "áx"])
    assert Enum.any?(resultado.errores, &String.contains?(&1, "\"á\" en posición 1"))
    assert Enum.any?(resultado.errores, &String.contains?(&1, "\"x\" en posición 2"))
  end

  test "no pierde errores comprobables cuando los parámetros son inválidos" do
    resultado = ValidadorParentesis.propuesta(["texto", "0", ")x"])
    refute resultado.valida
    assert length(resultado.errores) == 5
  end

  test "rechaza la cadena vacía y los campos incompletos" do
    refute ValidadorParentesis.propuesta(["3", "2", ""]).valida
    refute ValidadorParentesis.propuesta(["3", "2"]).valida
    assert {:error, _} = ValidadorParentesis.parametros(["3", "2", "extra"])
  end

  test "exige enteros positivos y p menor o igual que n" do
    assert {:ok, {3, 2}} = ValidadorParentesis.parametros(["3", "2"])

    for campos <- [["0", "1"], ["3", "4"], ["3", "0"], ["3.0", "2"], ["3x", "2"]] do
      assert {:error, _} = ValidadorParentesis.parametros(campos)
    end
  end

  test "la lectura conserva líneas físicas al ignorar comentarios y vacíos" do
    ruta = Path.expand("../datos/invalido/propuestas.txt", __DIR__)
    registros = ruta |> LectorParentesis.registros() |> Enum.to_list()
    assert {2, ["3", "2", "(()())"]} = hd(registros)
    assert {7, ["3", "2", "((a"]} in registros
    assert {9, ["3", "2", ""]} in registros
    refute Enum.any?(registros, fn {linea, _} -> linea in [1, 5, 6] end)
  end
end
