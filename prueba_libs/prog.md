# 📄 ARCHIVO DE AYUDA: LECTURA DEL FRAMEBUFFER EN ENSAMBLADOR



## 1. Introducción al Programa

Este programa en Ensamblador x86_64 para Linux tiene un objetivo claro: **obtener las dimensiones reales y físicas de tu monitor**. 

A diferencia de programas anteriores que le preguntaban a la "ventana de la terminal" cuántas letras cabían en ella, este programa se comunica **directamente con el controlador de la tarjeta gráfica** a través del sistema de archivos de Linux.

## 2. Conceptos Clave del Sistema Operativo

Para entender cómo funciona el código, hay que comprender tres pilares de Linux:

* **Todo es un archivo:** En Linux, el hardware se representa como archivos. Tu tarjeta gráfica y monitor se exponen en la ruta `/dev/fb0` (Framebuffer 0). Leer o interactuar con este archivo es interactuar con los píxeles de la pantalla.
* **La llamada IOCTL (Input/Output Control):** Es una llamada al sistema (`syscall 16`) que se usa como una "navaja suiza". Cuando `sys_read` o `sys_write` no son suficientes para hablar con un hardware (porque no queremos leer píxeles, sino pedir configuraciones), usamos `ioctl`.
* **El código mágico `0x4600`:** En C, este código se llama `FBIOGET_VSCREENINFO`. Es un número de comando específico del kernel de Linux que le dice al Framebuffer: *"Por favor, rellena mi espacio de memoria con la estructura de datos que contiene la configuración actual de la pantalla"*.

## 3. Análisis Paso a Paso del Código

El flujo de ejecución del programa se divide en 4 grandes bloques:

### Paso 1: Abrir el Dispositivo
```nasm
sys_open fb_path, O_RDONLY, 0
mov r15, rax
```
Intentamos abrir el archivo `/dev/fb0` en modo de solo lectura (`O_RDONLY`). Si la operación tiene éxito, Linux nos devuelve un **File Descriptor** (un número identificador), que guardamos en el registro `r15` de forma segura para usarlo después.

### Paso 2: Ejecutar IOCTL
```nasm
mov rdi, r15            ; File descriptor (/dev/fb0)
mov rsi, FBIOGET_VSCREENINFO ; ¿Qué queremos hacer?
mov rdx, fb_var_info    ; ¿Dónde dejamos los datos?
mov rax, SYS_IOCTL      ; Llamada 16
syscall
```
Aquí ocurre la magia. Le pasamos a la llamada al sistema el puntero a nuestra variable `fb_var_info` (que es un bloque vacío de 160 bytes que reservamos en la sección `.bss`). El kernel de Linux toma ese bloque y lo rellena con la estructura de C llamada `fb_var_screeninfo`.

### Paso 3: Extraer los Datos (Los Offsets)
En C, las estructuras ponen un dato detrás de otro. Como en Ensamblador no tenemos nombres de variables dentro de las estructuras, tenemos que acceder a la memoria sumando bytes (offsets) desde el inicio:

* **Resolución X (`+ 0` bytes):** El primer dato de la estructura es el ancho en píxeles (32 bits = 4 bytes). Por eso usamos `dword [fb_var_info + 0]`.
* **Resolución Y (`+ 4` bytes):** El segundo dato es el alto en píxeles. Saltamos los primeros 4 bytes. `dword [fb_var_info + 4]`.
* **Alto Físico (`+ 88` bytes):** Contando el tamaño de todos los datos internos de la estructura original de Linux, el alto en milímetros se encuentra exactamente en el byte 88.
* **Ancho Físico (`+ 92` bytes):** Inmediatamente después del alto, se encuentra el ancho en milímetros en el byte 92.

*Nota: Usamos el registro `edi` (32 bits) y le hacemos un `xor rdi, rdi` previo para limpiar la parte alta de los 64 bits, asegurándonos de que no haya "basura" en la memoria al pasarlo a la función `print_int`.*

### Paso 4: Cierre Limpio
```nasm
sys_close r15
sys_exit 0
```
Como buenos ciudadanos del sistema operativo, una vez que hemos leído la información, cerramos el archivo (`/dev/fb0`) y terminamos el programa devolviendo un código `0` (éxito) al sistema.

## 4. Problemas Comunes y Permisos

Si el programa devuelve el error programado **"Error: No se pudo leer /dev/fb0"**, casi siempre se debe a una protección de Linux.

Por defecto, solo el administrador (`root`) o los usuarios que pertenecen al grupo especial `video` pueden leer directamente el hardware del Framebuffer para evitar que programas maliciosos espíen la pantalla. 

**Soluciones:**
1.  **Ejecución temporal:** Correr el programa con `sudo ./bin/main`.
2.  **Solución permanente:** Añadir tu usuario al grupo correspondiente ejecutando `sudo usermod -aG video tu_nombre_de_usuario` y reiniciando el equipo.