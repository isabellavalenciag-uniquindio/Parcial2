# Ejercicio 4: paréntesis balanceados

Trabajo del ejercicio 4 del Parcial 2 de Programación III, desarrollado en la rama
`branch-carlos`. El ejercicio 1 se trabaja por separado en `Branch-isa`.

## Etapa actual

Lectura perezosa de los dos archivos de entrada, validación recursiva de
parámetros y cadenas propuestas, y generación recursiva de soluciones mediante
un Stream. Cada cadena se escribe al consumirla, sin guardar todas las soluciones
en una lista. También se obtiene solo la primera solución del caso grande
`n=18, p=18` y se consume un Stream infinito de tamaños hasta alcanzar 1000
soluciones. Los apartados de código del ejercicio 4 están implementados.

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
- `primera_n18_p18.txt`: únicamente la primera solución de ese caso grande.
- `secuencia_parentesis.csv`: encabezado `n;total` y tamaños del 1 al 8, inclusive.

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
elixir pruebas/streams_parentesis_test.exs
```

Para ejecutar las 21 pruebas juntas:

```powershell
elixir -r pruebas/validador_parentesis_test.exs -r pruebas/generador_parentesis_test.exs pruebas/streams_parentesis_test.exs
```

## Primera solución del caso grande

El programa consume `GeneradorParentesis.generar(18, 18)` mediante
`Stream.take(1)` y escribe una sola línea en `primera_n18_p18.txt`. La primera
cadena tiene 18 aperturas seguidas de 18 cierres, porque siempre se intenta abrir
antes de cerrar y la profundidad permitida es 18. Al completar esa cadena, el
consumidor se detiene y el generador no explora las ramas restantes.

## Stream infinito de crecimiento

`codigo/secuencia_parentesis.ex` construye la fuente infinita con
`Stream.iterate(1, &(&1 + 1))` y transforma cada tamaño perezosamente en
`{n, total}`. El total se calcula consumiendo el generador recursivo con `p=n`
mediante `Enum.count/1`; no se construye una lista de soluciones ni se usa una
fórmula para reemplazar la enumeración.

El escritor consume con `Enum.reduce_while/3`: escribe el registro actual y,
si su total es mayor o igual a 1000, devuelve `{:halt, ...}`. Por eso incluye
`n=8`, con 1430 soluciones, y no solicita ni calcula `n=9`. El Stream de origen
sigue siendo infinito; es su consumo el que tiene una condición de parada.

El CSV esperado es:

```csv
n;total
1;1
2;2
3;5
4;14
5;42
6;132
7;429
8;1430
```

## Evidencias para la entrega

`datos/valido`, `datos/invalido` y `datos/limite` contienen los casos de prueba;
sus resultados quedan en las carpetas correspondientes de `salida`. Las pruebas
automatizadas comprueban también que no se pida una segunda solución del caso
grande ni un noveno tamaño después de alcanzar el umbral.

Para la entrega académica aún se debe preparar el informe PDF con entradas,
resultados, pruebas y reflexión sobre el uso de IA, y el video individual de
sustentación. Este README contiene instrucciones y explicaciones para apoyarlos.
