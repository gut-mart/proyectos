%include "lib/constants.inc"
%include "lib/sys_macros.inc"

; -----------------------------------------------------------------
; Funciones de tus librerías
; -----------------------------------------------------------------
extern file_open
extern file_write
extern file_close

extern print_string
extern print_nl

; -----------------------------------------------------------------
; Sección de Datos
; -----------------------------------------------------------------
section .data
    nombre_archivo db "diario.txt", 0
    
    ; El mensaje a escribir (el '10' al final es el salto de línea \n)
    mensaje        db "¡Hola! Este archivo fue creado desde Ensamblador.", 10
    len_mensaje    equ $ - mensaje  ; Calcula la longitud exacta automáticamente

    msg_exito      db "=> EXITO: Revisa tu carpeta, el archivo 'diario.txt' fue creado.", 0
    msg_error      db "=> ERROR: No se pudo manipular el archivo.", 0

; -----------------------------------------------------------------
; Código Principal
; -----------------------------------------------------------------
default rel
section .text
    global _start

_start:
    ; 1. ABRIR / CREAR EL ARCHIVO
    mov rdi, nombre_archivo
    mov rsi, O_CREAT | O_WRONLY  ; Crear si no existe + Modo escritura
    mov rdx, 420                 ; Permisos 0644 (Lectura/Escritura para el dueño)
    call file_open
    
    ; Verificar si hubo un error al abrir (RAX negativo)
    cmp rax, 0
    jl error_archivo
    
    ; Guardamos el File Descriptor devuelto por el sistema
    mov r12, rax                 ; Usamos R12 porque es un registro seguro

    ; 2. ESCRIBIR EN EL ARCHIVO
    mov rdi, r12                 ; Pasamos el File Descriptor
    mov rsi, mensaje             ; Puntero al texto a escribir
    mov rdx, len_mensaje         ; Cantidad de bytes a escribir
    call file_write

    ; 3. CERRAR EL ARCHIVO
    mov rdi, r12                 ; Pasamos el File Descriptor
    call file_close

    ; 4. AVISAR AL USUARIO DEL ÉXITO
    mov rdi, msg_exito
    call print_string
    call print_nl

    sys_exit 0                   ; Salir limpiamente

error_archivo:
    mov rdi, msg_error
    call print_string
    call print_nl
    sys_exit 1                   ; Salir con código de error