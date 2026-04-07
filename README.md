# Statistical Analyzer in x86-64 Assembly

Sistema de análisis estadístico implementado en ensamblador x86-64 que procesa un archivo de notas y genera métricas como media, mediana, moda, desviación estándar y un histograma configurable.

---

## 1. Introducción

El presente proyecto consiste en el desarrollo de un sistema de análisis estadístico implementado en ensamblador x86-64, el cual procesa un archivo de notas y genera métricas como la media, mediana, moda y desviación estándar, además de un histograma configurable. El sistema utiliza un archivo de configuración para definir parámetros como el intervalo de agrupación, el carácter de representación y el color de salida, permitiendo así adaptar la visualización de los resultados.

---

## 2. Objetivos

### 2.1 Objetivo general
Desarrollar un sistema de análisis estadístico en ensamblador x86-64 capaz de leer archivos de configuración y datos, procesar la información de forma eficiente y generar métricas estadísticas junto con un histograma representativo en consola.

### 2.2 Objetivos específicos
- Implementar la lectura y validación de un archivo de configuración que permita parametrizar el comportamiento del sistema. 
- Diseñar un mecanismo de parsing para procesar archivos de datos de manera eficiente, utilizando lectura por bloques. 
- Calcular métricas estadísticas fundamentales como media, mediana, moda y desviación estándar a partir de los datos procesados.  
- Construir un histograma configurable que represente la distribución de las notas según el intervalo definido.
- Construir un histograma configurable que represente la distribución de las notas según el intervalo definido.
- Desarrollar un sistema de impresión en consola que muestre los resultados de forma clara y estructurada, incluyendo soporte para colores mediante códigos ANSI.  

---

## 3. Descripción general del sistema

El sistema opera a partir de dos archivos de entrada: un archivo de configuración (`config.ini`) y un archivo de datos (`notas.txt`). Inicialmente, se lee y valida el archivo de configuración, extrayendo los parámetros necesarios para el funcionamiento del programa. Posteriormente, se realiza la lectura del archivo de notas mediante un enfoque de procesamiento por bloques, identificando y almacenando los valores numéricos correspondientes a cada línea.

Una vez recopilados los datos, el sistema procede al cálculo de las métricas estadísticas principales. En paralelo, se construye un histograma basado en el intervalo definido en la configuración, agrupando las notas en rangos específicos. Finalmente, se genera la salida en consola, donde se presentan las estadísticas calculadas y la representación gráfica del histograma, aplicando el formato y color definidos por el usuario.

Flujo general:

config.ini → lectura y validación → notas.txt → parsing → cálculo estadístico → generación de histograma → impresión

---

## 4. Diagrama de flujo

Aquí se explica el proceso del programa en ensamblador en detalle, con fines de que sea legible se dividirá el diagrama de flujo en 6 partes:
-Inicio e inicialización
-Lectura y validación de `config.ini`
-Lectura de `notas.txt`
-Verificación de datos validos
-Procesamiento principal
-Salida final y manejo de errores

### 4.1 Inicio e inicalización

Este diagrama representa la etapa inicial del programa, comenzando en el punto de entrada `_start`, donde se realiza la preparación básica antes del procesamiento de datos.
Inicialmente, se inicializa el buffer `char_buf` para asegurar un estado conocido en memoria. Luego, se invoca la subrutina `leer_config`, encargada de abrir, leer y validar el archivo `config.ini`.

El resultado de esta operación se devuelve en el registro `eax`, el cual determina el flujo de ejecución:
- `eax = 0`: la configuración es válida y el programa continúa normalmente.
- `eax = 1`: error al leer el archivo.
- `eax = -2`: archivo leído pero con contenido inválido.
- Otro valor: error al abrir el archivo.

![Diagrama de inicio](images/inicio.png)

### 4.2 Lectura y validación de `config.ini`


Este diagrama representa la subrutina `leer_config`, encargada de abrir, leer y validar el archivo de configuración `config.ini`.
El proceso inicia con la apertura del archivo mediante la syscall `open`. Si ocurre un error (valor negativo en `rax`), la función retorna `eax = -1`. En caso contrario, se procede a leer su contenido en memoria utilizando `read`. Si esta operación falla, se cierra el archivo y se retorna `eax = 1`.
Una vez leído correctamente, el archivo es cerrado y se inicia el proceso de parsing línea por línea. Durante esta etapa, se ignoran espacios, saltos de línea y comentarios, y se buscan las claves esperadas: `COLOR`, `INTERVALO` y `CARACTER`. Cuando se detecta una clave válida, se parsea su valor correspondiente y se almacena en memoria, marcando además una bandera de validación.

Al finalizar el recorrido del archivo, se verifica que todas las claves hayan sido encontradas y que sus valores cumplan las restricciones establecidas:
- `COLOR` debe estar en el rango de 1 a 4.
- `INTERVALO` debe estar entre 1 y 100.
- `CARACTER` debe ser distinto de cero.

Si alguna de estas condiciones no se cumple, la función retorna `eax = -2`, indicando configuración inválida. En caso contrario, la función finaliza exitosamente retornando `eax = 0`.

![Diagrama de inicio](images/lectura_config.png)

### 4.3 Lectura de `notas.txt`




---

## 5. Arquitectura del programa

Descripción de la organización modular del sistema.

Módulos principales:
- _start  
- leer_config  
- leer_notas  
- calcular_estadisticas  
- calcular_histograma  
- imprimir_reporte  

Explicación breve de la función de cada módulo.

---

## 6. Formato de entrada

### 6.1 Archivo de configuración (config.ini)

Ejemplo:

COLOR:1  
INTERVALO:50  
CARACTER:@  

Descripción de cada parámetro, su significado y restricciones.

---

### 6.2 Archivo de datos (notas.txt)

Ejemplo:

Nombre Apellido 85  
Otro Nombre 92  

Descripción del formato de cada línea y del rango de valores permitidos.

---

## 7. Procesamiento de datos

### 7.1 Parsing de configuración

Explicación de cómo se identifican las claves, cómo se leen los valores y cómo se validan.

---

### 7.2 Parsing de notas mediante lectura por bloques

Explicación del enfoque de lectura tipo streaming, manejo de buffers y lógica de procesamiento.

---

### 7.3 Estructuras de almacenamiento

Descripción de las estructuras utilizadas para almacenar y procesar los datos:
- Arreglo de notas  
- Arreglo ordenado  
- Arreglo de frecuencias  
- Arreglo de bins  

---

## 8. Cálculo estadístico

### 8.1 Media

Descripción del cálculo de la media.

---

### 8.2 Mediana

Descripción del método de ordenamiento y el cálculo para casos pares e impares.

---

### 8.3 Moda

Descripción del uso del arreglo de frecuencias para determinar la moda.

---

### 8.4 Desviación estándar

Descripción de la fórmula utilizada y del uso de operaciones en punto flotante.

---

## 9. Generación del histograma

Explicación de cómo se calcula la cantidad de bins, cómo se asignan las notas a cada bin y cómo se manejan los casos límite.

---

## 10. Sistema de impresión

Descripción del mecanismo de impresión, uso de syscalls y funciones auxiliares.

---

## 11. Uso de códigos ANSI

Explicación del uso de códigos ANSI para la representación de colores en la salida.

---

## 12. Manejo de errores

Descripción de los errores contemplados:
- Error al abrir archivos  
- Error al leer archivos  
- Configuración inválida  
- Ausencia de datos válidos  

---

## 13. Pruebas realizadas

Descripción de los distintos tipos de pruebas realizadas:
- Casos normales  
- Casos extremos  
- Casos de error  

---


## 14. Conclusión

Conclusión del proyecto, incluyendo resultados obtenidos, aprendizajes y relevancia del sistema desarrollado.

---
