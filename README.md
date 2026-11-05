# Ejemplo 1: Robot de rescate con energía limitada y mapa SVG

Parcial 2 - Programación III , Universidad del Quindío.
Autor : Isabella Valencia Gómez

Este programa busca todos los recorridos posibles de un robot desde la casilla S hasta la meta M sin pasar dos veces por la misma casilla ni superar la batería disponible.
Después calcula los recorridos con menos movimientos y los de menor energía, y dibuja la ruta óptima en un SVG.

## Qué hay en el repositorio

`rescate.exs`: programa principal
`codigo/`: módulos del programa
`datos/`: archivos de entrada (`edificio.txt`, `terrenos.csv`, `bateria.txt`) y casos de prueba
`salida/`: archivos que genera el programa

## Cómo ejecutarlo
Desde la terminal colocamos:

    elixir rescate.exs

Si no se indica nada más, el programa usa los datos de `datos/validos`.

Para ejecutar un caso específico, escribe la carpeta del caso después del comando:

    elixir rescate.exs datos/[caso]

Por ejemplo:

    elixir rescate.exs datos/sinruta


## Qué genera

En `salida/` quedan:

- `recorridos_rescate.csv`: todos los recorridos encontrados
- `resumen_rescate.txt`: total, recorridos con menos movimientos y con menor energía
- `ruta_optima.svg`: mapa con la ruta de menor energía se abre en el navegador
- `validacion_edificio.txt`: errores de validación, si los hay
- `expansion_energia.txt`: pasos del Stream de relajación de energía


