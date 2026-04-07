# StatASM – Statistical Analyzer in x86-64 Assembly

Sistema de análisis estadístico implementado en ensamblador x86-64 que procesa un archivo de notas y genera métricas como media, mediana, moda, desviación estándar y un histograma configurable.

---

## 1. Introducción

Descripción del contexto del proyecto, el problema que se aborda, la justificación del uso de ensamblador y el alcance general del sistema.

---

## 2. Objetivos

### 2.1 Objetivo general
Descripción del objetivo principal del sistema.

### 2.2 Objetivos específicos
- Objetivo específico 1  
- Objetivo específico 2  
- Objetivo específico 3  
- Objetivo específico 4  

---

## 3. Descripción general del sistema

Explicación del flujo completo del sistema desde la lectura de archivos hasta la generación de resultados.

Flujo general:

config.ini → lectura y validación → notas.txt → parsing → cálculo estadístico → generación de histograma → impresión

---

## 4. Diagrama de flujo

Diagrama que representa el funcionamiento general del sistema.

(Insertar aquí el diagrama de flujo, imagen o Mermaid si se desea)

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

## 14. Limitaciones

- Limitación 1  
- Limitación 2  
- Limitación 3  

---

## 15. Mejoras futuras

- Mejora 1  
- Mejora 2  
- Mejora 3  

---

## 16. Conclusión

Conclusión del proyecto, incluyendo resultados obtenidos, aprendizajes y relevancia del sistema desarrollado.

---
