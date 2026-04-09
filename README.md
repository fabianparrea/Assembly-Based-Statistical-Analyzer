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

El archivo `config.ini` se recorre byte por byte, ignorando espacios, saltos de línea y comentarios. Para cada línea se verifica si coincide con alguna de las claves esperadas (`COLOR`, `INTERVALO`, `CARACTER`). Esta verificación se realiza mediante comparaciones directas de strings, permitiendo identificar la clave al inicio de cada línea.

Ejemplo del chequeo de claves:

    mov rdi, rbx
    mov rsi, key_color
    call starts_with
    test eax, eax
    jz .check_intervalo

Cuando se detecta una clave válida, se procede a parsear el valor numérico correspondiente desde la posición adecuada dentro de la línea. Este valor se almacena en memoria y se marca una bandera indicando que la clave fue encontrada.

    lea rdi, [rbx + 6]
    call parse_uint_line
    mov [color_value], eax
    mov byte [found_color], 1

Una vez procesado todo el archivo, se realiza una validación final para asegurar que todas las claves estén presentes y que sus valores estén dentro de los rangos permitidos.

    mov eax, [color_value]
    cmp eax, 1
    jb .cfg_bad
    cmp eax, 4
    ja .cfg_bad

---

### 6.2 Parsing de notas mediante lectura por bloques

El archivo `notas.txt` se procesa utilizando lectura por bloques de 4096 bytes, lo cual permite manejar archivos grandes sin depender de su tamaño total.

    mov eax, 0
    mov rdi, r12
    mov rsi, notas_chunk
    mov edx, 4096
    syscall

Cada bloque leído se procesa carácter por carácter. Cuando se detecta un dígito, se construye el número actual acumulando su valor en base 10.

    imul eax, eax, 10
    sub dl, '0'
    add eax, edx
    mov [cur_num], eax

Esto implementa la relación:

    número = número * 10 + dígito

Cuando se encuentra un separador (espacio, tab o salto de línea), el número acumulado se considera como candidato válido dentro de la línea.

    mov eax, [cur_num]
    mov [line_candidate], eax
    mov byte [has_candidate], 1

Al finalizar la línea, se verifica que el candidato sea válido (entre 0 y 100) y se almacena en memoria junto con la actualización de los acumuladores.

    cmp eax, 100
    ja .reset_line

    mov [notes_arr + rcx*4], eax
    inc dword [notes_count]
    add qword [sum_notes], rdx
    inc dword [freq_arr + rax*4]



---

### 6.3 Estructuras de almacenamiento

Las estructuras de datos utilizadas se definen en memoria estática y permiten almacenar eficientemente la información procesada.

    notes_arr       resd 65536
    notes_sorted    resd 65536
    freq_arr        resd 101
    bins_arr        resd 128

- `notes_arr`: almacena las notas en el orden original.
- `notes_sorted`: copia utilizada para ordenar y calcular la mediana.
- `freq_arr`: arreglo de frecuencias para calcular la moda.
- `bins_arr`: almacenamiento de los intervalos del histograma.

Variables auxiliares:

    notes_count     resd 1
    sum_notes       resq 1
    cur_num         resd 1
    in_number       resb 1
    line_candidate  resd 1
    has_candidate   resb 1

Estas variables permiten controlar el estado del parser y los acumuladores necesarios para el cálculo posterior.

---

## 7. Cálculo estadístico

### 7.1 Media

La media se calcula como:

    media = suma_notas / cantidad_notas

Se utiliza SSE para realizar la división en punto flotante:

    mov rax, [sum_notes]
    cvtsi2sd xmm0, rax
    mov eax, [notes_count]
    cvtsi2sd xmm1, rax
    divsd xmm0, xmm1

Luego se escala para mantener precisión decimal en la impresión:

    media_escalada = media * 10

---

### 7.2 Mediana

Se ordena el arreglo `notes_sorted` mediante insertion sort, el cual inserta cada elemento en su posición correcta dentro de la parte ya ordenada del arreglo.

    mov eax, [notes_sorted + r12*4]

La mediana depende de la cantidad de datos:

- Si es impar:

    mediana = elemento_central

- Si es par:

    mediana = (elemento_central_1 + elemento_central_2) / 2

La decisión se realiza así:

    test eax, 1
    jnz .median_odd

---

### 7.3 Moda

La moda corresponde al valor con mayor frecuencia dentro del arreglo `freq_arr`.

    moda = argmax(freq_arr[i])

Implementación:

    mov eax, [freq_arr + rbx*4]
    cmp eax, r12d
    jle .next_mode

Se guarda el índice con mayor frecuencia encontrada.

---

### 7.4 Desviación estándar

Se calcula utilizando:

    σ = sqrt( Σ(x - μ)^2 / N )

Implementación:

    subsd xmm1, xmm7
    mulsd xmm1, xmm1
    addsd xmm2, xmm1

    divsd xmm2, xmm3
    sqrtsd xmm2, xmm2

Escalado:

    σ_escalada = σ * 100

---

## 8. Generación del histograma

Se calcula la cantidad de intervalos:

    bin_count = floor(99 / intervalo) + 1

    mov eax, 99
    div ecx
    inc eax
    mov [bin_count], eax

Cada nota se asigna a un intervalo correspondiente:

    índice = (nota - 1) / intervalo

    dec eax
    div dword [intervalo_value]

Finalmente, se incrementa el contador del bin:

    inc dword [bins_arr + rax*4]

---

## 9. Sistema de impresión

La salida se realiza mediante la syscall `write`, enviando directamente los datos al descriptor estándar de salida.

    mov eax, 1
    mov edi, 1
    syscall

Se implementan rutinas auxiliares para convertir números a ASCII y poder imprimirlos correctamente en consola.

---

## 10. Uso de códigos ANSI

Los códigos ANSI se utilizan para modificar el color de salida en la terminal.

    ansi_red    db 27,'[','3','1','m',0

Se selecciona el color según el valor de configuración:

    cmp eax, 1
    je .red

Al finalizar la impresión, se restablece el color:

    mov rsi, ansi_reset
    call print_cstr

---

## 11. Manejo de errores

Se verifican errores en cada operación crítica como apertura y lectura de archivos.

    test rax, rax
    js .open_fail

Se utilizan distintos códigos de retorno:

    -1 → open fail  
    1  → read fail  
    -2 → config inválido  

El programa finaliza con:

    mov eax, 60
    mov edi, 1
    syscall

En caso exitoso:

    mov eax, 60
    xor edi, edi
    syscall

---

## 12. Compilación y ejecución del programa

El programa fue desarrollado y probado en un entorno Linux Lubuntu sobre arquitectura x86-64.

Asumiendo que los archivos `histograma.asm`, `config.ini` y `notas.txt` se encuentran en la misma carpeta, se siguen los siguientes pasos desde la terminal:

1. Ensamblado del código:

    nasm -f elf64 -o histograma.o histograma.asm

Este comando utiliza NASM para convertir el archivo ensamblador en un archivo objeto (`.o`) en formato ELF64, el cual es necesario para el enlazado.

2. Enlazado:

    ld -o histograma histograma.o

Este paso genera el ejecutable final (`histograma`) a partir del archivo objeto.

3. Ejecución:

    ./histograma

Este comando ejecuta el programa, el cual leerá los archivos de entrada y mostrará los resultados en la terminal.

Los nombres de los archivos generados pueden modificarse, sin embargo, se recomienda mantener nombres consistentes (`histograma.o`, `histograma`) para facilitar la organización y comprensión del flujo de compilación.

---

## 13. Resultados

A continuación se muestra un ejemplo de ejecución del programa utilizando el archivo `config.ini` y el archivo `notas.txt` proporcionados.

La salida se presenta directamente en la terminal, incluyendo las métricas estadísticas y el histograma generado.

![Resultado en terminal](images/resultado.png)

---

## 14. Conclusión

Se logró implementar un analizador estadístico completo en ensamblador x86-64, capaz de leer archivos externos, procesar datos y generar resultados en consola sin depender de librerías de alto nivel. El programa utiliza syscalls para el manejo de archivos y salida, implementa parsing manual de texto mediante lectura por bloques y hace uso de estructuras de datos en memoria para almacenar y procesar la información.

Los cálculos estadísticos, incluyendo media, mediana, moda y desviación estándar, se realizan utilizando registros SSE para manejar valores en punto flotante. Además, se construye un histograma configurable a partir de los parámetros definidos en `config.ini`, permitiendo ajustar la visualización de los resultados según el intervalo, el carácter y el color seleccionados.

El desarrollo del proyecto implicó trabajar directamente con conceptos de bajo nivel como manejo de memoria, control de flujo, parsing de datos y uso de la ABI del sistema, logrando una solución funcional y estructurada acorde a los requerimientos planteados.
