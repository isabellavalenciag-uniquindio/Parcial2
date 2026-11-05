# Ejercicio 4: paréntesis balanceados

Trabajo del ejercicio 4 del Parcial 2 de Programación III, desarrollado en la rama
`branch-carlos`. El ejercicio 1 se trabaja por separado en `Branch-isa`.

## Etapa actual

Lectura perezosa de los dos archivos de entrada, validación recursiva de
parámetros y cadenas propuestas, y generación recursiva de soluciones mediante
un Stream. Cada cadena se escribe al consumirla, sin guardar todas las soluciones
en una lista. Los dos apartados adicionales de Streams quedan para el siguiente paso.

## Ejecutar

Desde la carpeta raíz del repositorio, con Elixir instalado:

```powershell
elixir parentesis.exs
elixir parentesis.exs datos/invalido
elixir parentesis.exs datos/limite
```

Sin argumentos se usa `datos/valido`. También se puede indicar otra carpeta que
contenga `parametros.csv` y `propuestas.txt`.

Los reportes se crean o reemplazan en `salida/<nombre_de_la_carpeta>/`:

- `validacion_parametros.txt`: formato y rango de cada par `n;p`.
- `verificacion_parentesis.txt`: resultado de cada propuesta y motivos de error.
- `parentesis_n<N>_p<P>.txt`: soluciones para cada par solicitado y total al final.

El total de cada par también se muestra en pantalla. Si un registro de
`parametros.csv` es inválido, se completan los reportes pero no se generan
soluciones hasta corregir el archivo. Las propuestas inválidas se informan y no
impiden generar soluciones cuando los parámetros sí son válidos.

Los archivos de entrada se leen con `File.stream!/1`. Las líneas vacías y los
comentarios cuyo primer carácter no blanco es `#` se ignoran. La numeración de
los errores conserva las líneas físicas del archivo. Las posiciones de los
caracteres en los mensajes comienzan en 1; un prefijo de longitud 3 termina en
la posición 3. Los espacios alrededor de cada campo se eliminan; los espacios
dentro de una cadena son caracteres inválidos.

## Cómo funciona la validación

`codigo/lector_parentesis.ex` devuelve un Stream de registros `{linea, campos}`.
El archivo principal consume cada registro y escribe su resultado inmediatamente.

`codigo/validador_parentesis.ex` recorre las cadenas mediante recursión propia,
sin utilizar `Enum` ni `Stream`. Lleva la longitud, el balance, la profundidad
máxima y las primeras posiciones problemáticas. Un `(` incrementa el balance;
un `)` lo disminuye. El balance nunca debe ser negativo y debe terminar en cero.
La profundidad máxima no puede superar `p`.

Una propuesta inválida se registra y se continúa con las demás. Si `n` o `p`
son incorrectos, se informan además los problemas de la cadena que sí puedan
comprobarse. No se puede comprobar la longitud esperada sin un `n` válido, ni
el exceso de profundidad sin un `p` válido.

## Cómo funciona el generador

`codigo/generador_parentesis.ex` usa `Stream.unfold/2` para entregar una solución
por vez. Su función recursiva `siguiente/3` explora prefijos y conserva una pila
de ramas pendientes. Cada estado contiene `{prefijo, abiertos, cerrados}`.

- Agrega `(` cuando `abiertos < n` y `abiertos - cerrados < p`.
- Agrega `)` cuando `cerrados < abiertos`.
- Entrega el prefijo cuando `abiertos == cerrados == n`.

La pila permite avanzar y retroceder en la búsqueda. Se coloca la rama de apertura
delante de la de cierre para intentar siempre `(` primero. Cuando se encuentra
una solución, la búsqueda se pausa hasta que se solicite la siguiente. Se guardan
prefijos pendientes, sin acumular las soluciones completas.

`codigo/escritor_parentesis.ex` consume el Stream con un contador y escribe cada
cadena directamente en el archivo. Para `n=3, p=2` el resultado es:

```text
(()())
(())()
()(())
()()()
Total: 4
```

## Pruebas

```powershell
elixir pruebas/validador_parentesis_test.exs
elixir pruebas/generador_parentesis_test.exs
```

## Próximos pasos

1. Guardar la primera solución para `n=18, p=18`, sin consumir las restantes.
2. Stream infinito de tamaños, detenido después de `n=8`, con total 1430.

El generador ya permite consumir solo una solución; esa propiedad se verifica en
las pruebas. Falta incorporar el archivo `primera_n18_p18.txt` y el apartado
`secuencia_parentesis.csv` a la ejecución principal.
