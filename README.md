# Statistical Analyzer in x86-64 Assembly

Sistema de análisis estadístico implementado en ensamblador x86-64 que procesa un archivo de notas y genera métricas como media, mediana, moda, desviación estándar y un histograma configurable.

---

## 1. Introducción

El presente proyecto consiste en el desarrollo de un sistema de análisis estadístico implementado en ensamblador x86-64, el cual procesa un archivo de notas y genera métricas como la media, mediana, moda y desviación estándar, además de un histograma configurable. El sistema utiliza un archivo de configuración para definir parámetros como el intervalo de agrupación, el carácter de representación y el color de salida, permitiendo así adaptar la visualización de los resultados.

---


## 2. Descripción general del sistema

El sistema opera a partir de dos archivos de entrada: un archivo de configuración (`config.ini`) y un archivo de datos (`notas.txt`). Inicialmente, se lee y valida el archivo de configuración, extrayendo los parámetros necesarios para el funcionamiento del programa. Posteriormente, se realiza la lectura del archivo de notas mediante un enfoque de procesamiento por bloques, identificando y almacenando los valores numéricos correspondientes a cada línea.

Una vez recopilados los datos, el sistema procede al cálculo de las métricas estadísticas principales. En paralelo, se construye un histograma basado en el intervalo definido en la configuración, agrupando las notas en rangos específicos. Finalmente, se genera la salida en consola, donde se presentan las estadísticas calculadas y la representación gráfica del histograma, aplicando el formato y color definidos por el usuario.

Flujo general:

config.ini → lectura y validación → notas.txt → parsing → cálculo estadístico → generación de histograma → impresión

---

## 3. Diagrama de flujo

Aquí se explica el proceso del programa en ensamblador en detalle, con fines de que sea legible se dividirá el diagrama de flujo en 6 partes:
-Inicio e inicialización
-Lectura y validación de `config.ini`
-Lectura de `notas.txt`
-Verificación de datos válidos
-Procesamiento principal
-Salida final y manejo de errores

### 3.1 Inicio e inicalización

Este diagrama representa la etapa inicial del programa, comenzando en el punto de entrada `_start`, donde se realiza la preparación básica antes del procesamiento de datos.
Inicialmente, se inicializa el buffer `char_buf` para asegurar un estado conocido en memoria. Luego, se invoca la subrutina `leer_config`, encargada de abrir, leer y validar el archivo `config.ini`.

El resultado de esta operación se devuelve en el registro `eax`, el cual determina el flujo de ejecución:
- `eax = 0`: la configuración es válida y el programa continúa normalmente.
- `eax = 1`: error al leer el archivo.
- `eax = -2`: archivo leído pero con contenido inválido.
- Otro valor: error al abrir el archivo.

![Diagrama de inicio](images/inicio.png)

### 3.2 Lectura y validación de `config.ini`


Este diagrama representa la subrutina `leer_config`, encargada de abrir, leer y validar el archivo de configuración `config.ini`.
El proceso inicia con la apertura del archivo mediante la syscall `open`. Si ocurre un error (valor negativo en `rax`), la función retorna `eax = -1`. En caso contrario, se procede a leer su contenido en memoria utilizando `read`. Si esta operación falla, se cierra el archivo y se retorna `eax = 1`.
Una vez leído correctamente, el archivo es cerrado y se inicia el proceso de parsing línea por línea. Durante esta etapa, se ignoran espacios, saltos de línea y comentarios, y se buscan las claves esperadas: `COLOR`, `INTERVALO` y `CARACTER`. Cuando se detecta una clave válida, se parsea su valor correspondiente y se almacena en memoria, marcando además una bandera de validación.

Al finalizar el recorrido del archivo, se verifica que todas las claves hayan sido encontradas y que sus valores cumplan las restricciones establecidas:
- `COLOR` debe estar en el rango de 1 a 4.
- `INTERVALO` debe estar entre 1 y 100.
- `CARACTER` debe ser distinto de cero.

Si alguna de estas condiciones no se cumple, la función retorna `eax = -2`, indicando configuración inválida. En caso contrario, la función finaliza exitosamente retornando `eax = 0`.

![Diagrama de inicio](images/lectura_config.png)

### 3.3 Lectura de `notas.txt`

Este diagrama representa la subrutina `leer_notas`, encargada de procesar el archivo `notas.txt` mediante lectura por bloques y parsing carácter por carácter.
Se inicializan las estructuras de datos necesarias: el arreglo de frecuencias (`freq_arr`), acumuladores (`sum_notes`, `notes_count`) y variables de estado del parser (`cur_num`, `in_number`, `line_candidate`, `has_candidate`).
El archivo se abre utilizando la syscall `open`. Si falla, la función retorna `eax = -1`. Luego, se realiza la lectura en bloques de 4096 bytes mediante `read`. Si ocurre un error de lectura, se cierra el archivo y se retorna `eax = 1`.

El contenido leído se procesa byte por byte. Cuando se detectan dígitos (`'0'..'9'`), se construye el número actual utilizando la relación: numero final = numero * 10 + digito

Cuando se encuentra un separador (espacio, tab o salto de línea), el número acumulado se considera como candidato de nota.
Al finalizar cada línea, se evalúa si existe un candidato válido (`has_candidate == 1`) y si cumple las condiciones:
- Valor entre 0 y 100.
- Espacio disponible en el arreglo (máximo 65536 elementos).

Si es válido, se almacena en `notes_arr` y `notes_sorted`, se incrementa el contador de notas, se acumula en `sum_notes` y se actualiza su frecuencia en `freq_arr`.
Caracteres inválidos dentro de una línea descartan el candidato actual, asegurando robustez ante formatos incorrectos.
Al alcanzar el final del archivo (EOF), se procesa una posible última línea pendiente. Finalmente, se cierra el archivo y la función retorna `eax = 0` si todo fue exitoso.

![Diagrama de inicio](images/lectura_config.png)

### 3.4 Verificación de datos válidos

Este diagrama representa la verificación posterior a la lectura del archivo `notas.txt`, donde se determina si existen datos válidos para procesar.
Se evalúa el valor de `notes_count`, que corresponde a la cantidad total de notas almacenadas durante la etapa de parsing.

- Si `notes_count = 0`, significa que no se encontraron notas válidas en el archivo. En este caso, el programa imprime un mensaje de error (`msg_empty`) y finaliza con un código de salida de error.
- Si `notes_count > 0`, el programa continúa hacia la etapa de procesamiento principal, donde se calculan las estadísticas y se genera el histograma.

Esta verificación evita realizar cálculos innecesarios y asegura que el sistema opere únicamente sobre datos válidos.

![Diagrama de inicio](images/verificacion.png)

### 3.5 Procesamiento principal

Este diagrama representa la etapa principal del programa, donde se procesan los datos obtenidos del archivo `notas.txt` para generar los resultados finales.
En primer lugar, se invoca la subrutina `calcular_estadisticas`, en la cual se obtienen las métricas principales:
- Media
- Mediana (a partir del ordenamiento de los datos)
- Moda (utilizando el arreglo de frecuencias)
- Desviación estándar

Se llama a `calcular_histograma`, donde se construye la distribución de las notas. Para ello, se determina la cantidad de intervalos (bins), se inicializan los contadores y se asigna cada nota a su rango correspondiente, incrementando su frecuencia.
Finalmente, se ejecuta la subrutina `imprimir_reporte`, encargada de mostrar los resultados en consola. Esta incluye la impresión de las estadísticas calculadas y del histograma, aplicando el color y el carácter definidos en el archivo de configuración.

![Diagrama de inicio](images/estadistica.png)

### 3.6 Salida final y manejo de errores

Este diagrama representa la etapa final del programa, donde se determina si la ejecución fue exitosa o si ocurrió algún error durante el proceso.
Se evalúa el resultado general del sistema:

- Si el proceso fue exitoso, el programa finaliza normalmente mediante `exit(0)`, indicando una ejecución correcta.
- Si ocurrió algún error, se identifica su tipo y se ejecuta la rutina correspondiente de manejo de errores.

Los posibles errores contemplados son:
- Error al abrir el archivo `config.ini`.
- Error al leer el archivo `config.ini`.
- Configuración inválida.
- Error al abrir el archivo `notas.txt`.
- Error al leer el archivo `notas.txt`.
- Ausencia de datos válidos.

En cada caso, se imprime un mensaje específico en consola para informar al usuario sobre la causa del fallo. Posteriormente, el programa finaliza mediante `exit(1)`, indicando que la ejecución terminó con error.

![Diagrama de inicio](images/salida.png)

---

## 4. Arquitectura del programa

El programa está organizado en módulos independientes, cada uno encargado de una etapa específica del flujo:

- `_start`: punto de entrada. Controla el flujo general del programa, maneja errores y coordina las llamadas a las demás subrutinas.
- `leer_config`: abre, parsea y valida el archivo `config.ini`, extrayendo los parámetros necesarios.
- `leer_notas`: procesa `notas.txt` mediante lectura por bloques, construyendo las notas y almacenándolas en memoria.
- `calcular_estadisticas`: calcula media, mediana, moda y desviación estándar a partir de los datos procesados.
- `calcular_histograma`: agrupa las notas en intervalos definidos y genera los conteos por bin.
- `imprimir_reporte`: imprime las estadísticas y el histograma en consola con formato y color.

Cada módulo trabaja sobre estructuras en memoria compartidas, evitando dependencias innecesarias y manteniendo el flujo secuencial.


---

## 5. Formato de entrada

### 5.1 Archivo de configuración (config.ini)


El archivo define los parámetros de visualización del programa.

Formato esperado:

COLOR:<valor>
INTERVALO:<valor>
CARACTER:<valor>

Restricciones:
- `COLOR`: entero entre 1 y 4.
- `INTERVALO`: entero entre 1 y 100.
- `CARACTER`: cualquier carácter ASCII no nulo.

Se permiten espacios, líneas vacías y comentarios.

---

### 5.2 Archivo de datos (notas.txt)

Cada línea contiene un nombre seguido de una nota numérica:

Ejemplo:

Nombre Apellido 85  
Otro Nombre 92  

Consideraciones:
- El nombre puede tener cualquier cantidad de palabras.
- La nota debe estar entre 0 y 100.
- Solo se toma el último número válido de cada línea.
- Líneas con contenido inválido son descartadas.

---

## 6. Procesamiento de datos

### 6.1 Parsing de configuración

El archivo `config.ini` se recorre byte por byte, ignorando espacios, saltos de línea y comentarios. Para cada línea se verifica si coincide con alguna clave válida.

Ejemplo del chequeo de claves:

    mov rdi, rbx
    mov rsi, key_color
    call starts_with
    test eax, eax
    jz .check_intervalo

Si la clave coincide, se parsea el valor numérico:

    lea rdi, [rbx + 6]
    call parse_uint_line
    mov [color_value], eax
    mov byte [found_color], 1

Al final se valida que todas las claves existan y estén en rango:

    mov eax, [color_value]
    cmp eax, 1
    jb .cfg_bad
    cmp eax, 4
    ja .cfg_bad

### 6.2 Parsing de notas mediante lectura por bloques

El archivo se lee en bloques de 4096 bytes:

    mov eax, 0
    mov rdi, r12
    mov rsi, notas_chunk
    mov edx, 4096
    syscall

Los números se construyen carácter por carácter:

    imul eax, eax, 10
    sub dl, '0'
    add eax, edx
    mov [cur_num], eax

Esto implementa:

    número = número * 10 + dígito

Al detectar un separador, se guarda el candidato:

    mov eax, [cur_num]
    mov [line_candidate], eax
    mov byte [has_candidate], 1

Y al final de línea se valida y guarda:

    cmp eax, 100
    ja .reset_line

    mov [notes_arr + rcx*4], eax
    inc dword [notes_count]
    add qword [sum_notes], rdx
    inc dword [freq_arr + rax*4]

### 6.3 Estructuras de almacenamiento

Las estructuras principales se definen en memoria:

    notes_arr       resd 65536
    notes_sorted    resd 65536
    freq_arr        resd 101
    bins_arr        resd 128

Se utilizan para almacenar las notas, mantener una copia ordenada, contar frecuencias y construir el histograma.

Variables auxiliares:

    notes_count     resd 1
    sum_notes       resq 1
    cur_num         resd 1
    in_number       resb 1
    line_candidate  resd 1
    has_candidate   resb 1

## 7. Cálculo estadístico

### 7.1 Media

Se calcula como:

    media = suma_notas / cantidad_notas

Implementación:

    mov rax, [sum_notes]
    cvtsi2sd xmm0, rax
    mov eax, [notes_count]
    cvtsi2sd xmm1, rax
    divsd xmm0, xmm1

Luego se escala para impresión:

    media_escalada = media * 10

---

### 7.2 Mediana

Primero se ordena el arreglo `notes_sorted` usando **insertion sort**, que consiste en tomar cada elemento e insertarlo en su posición correcta dentro de la parte ya ordenada del arreglo.

Ejemplo del movimiento de elementos:

    mov eax, [notes_sorted + r12*4]

La mediana se calcula según la cantidad de datos:

- Caso impar:

    mediana = elemento_central

- Caso par:

    mediana = (elemento_central_1 + elemento_central_2) / 2

Implementación de la decisión:

    test eax, 1
    jnz .median_odd

Caso par:

    add eax, edx
    imul eax, 10
    idiv ecx

---

### 7.3 Moda

Se define como el valor con mayor frecuencia:

    moda = argmax(freq_arr[i])

Implementación:

    mov eax, [freq_arr + rbx*4]
    cmp eax, r12d
    jle .next_mode

Se guarda el índice con mayor frecuencia:

    mov r13d, ebx
    mov [mode_value], r13d

---

### 7.4 Desviación estándar

Se calcula como:

    σ = sqrt( Σ(x - μ)^2 / N )

Implementación:

    subsd xmm1, xmm7
    mulsd xmm1, xmm1
    addsd xmm2, xmm1

Luego:

    divsd xmm2, xmm3
    sqrtsd xmm2, xmm2

Escalado:

    σ_escalada = σ * 100

---

## 8. Generación del histograma

Cantidad de bins:

    bin_count = floor(99 / intervalo) + 1

Implementación:

    mov eax, 99
    div ecx
    inc eax
    mov [bin_count], eax

Asignación de bin:

    índice = (nota - 1) / intervalo

Implementación:

    dec eax
    div dword [intervalo_value]

Incremento:

    inc dword [bins_arr + rax*4]

---

## 9. Sistema de impresión

Se utiliza la syscall `write`:

    mov eax, 1
    mov edi, 1
    syscall

Conversión de números:

    div ecx
    add dl, '0'

---

## 10. Uso de códigos ANSI

Ejemplo:

    ansi_red    db 27,'[','3','1','m',0

Selección:

    cmp eax, 1
    je .red

Reset:

    mov rsi, ansi_reset
    call print_cstr

---

## 11. Manejo de errores

Chequeo de errores:

    test rax, rax
    js .open_fail

Códigos de retorno:

    -1 → open fail  
    1  → read fail  
    -2 → config inválido  

Salida:

    mov eax, 60
    mov edi, 1
    syscall

Ejecución exitosa:

    mov eax, 60
    xor edi, edi
    syscall

  
## 12. Cómo Correr el programa

## 13. Resultados

---

## 14. Conclusión

Se logró implementar un analizador estadístico completo en ensamblador x86-64, capaz de leer archivos externos, procesar datos y generar resultados en consola sin depender de librerías de alto nivel. El programa utiliza syscalls para el manejo de archivos y salida, implementa parsing manual de texto mediante lectura por bloques y hace uso de estructuras de datos en memoria para almacenar y procesar la información.

Los cálculos estadísticos, incluyendo media, mediana, moda y desviación estándar, se realizan utilizando registros SSE para manejar valores en punto flotante. Además, se construye un histograma configurable a partir de los parámetros definidos en `config.ini`, permitiendo ajustar la visualización de los resultados según el intervalo, el carácter y el color seleccionados.

El desarrollo del proyecto implicó trabajar directamente con conceptos de bajo nivel como manejo de memoria, control de flujo, parsing de datos y uso de la ABI del sistema, logrando una solución funcional y estructurada acorde a los requerimientos planteados.

---
