%include "lib/constants.inc"
%include "lib/sys_macros.inc"

default rel         ; <-- SOLUCIÓN AL WARNING (Direccionamiento relativo)

; -----------------------------------------------------------------
; Constante para el ioctl del Framebuffer de Linux
; -----------------------------------------------------------------
%define FBIOGET_VSCREENINFO 0x4600

extern print_string
extern print_int
extern print_nl

; -----------------------------------------------------------------
; Sección de Datos
; -----------------------------------------------------------------
section .data
    fb_path     db "/dev/fb0", 0
    msg_titulo  db "=== INFO FISICA DEL MONITOR ===", 0
    msg_xres    db "Resolucion X (Pixeles): ", 0
    msg_yres    db "Resolucion Y (Pixeles): ", 0
    msg_xmm     db "Ancho Fisico (mm):      ", 0
    msg_ymm     db "Alto Fisico (mm):       ", 0
    msg_error   db "Error: No se pudo leer /dev/fb0 (Prueba con 'sudo')", 0

; -----------------------------------------------------------------
; Sección BSS
; -----------------------------------------------------------------
section .bss
    ; Reservamos 160 bytes para almacenar la estructura completa 
    ; fb_var_screeninfo del kernel de Linux
    fb_var_info resb 160

; -----------------------------------------------------------------
; Código Principal
; -----------------------------------------------------------------
section .text
    global _start

_start:
    ; Imprimir título
    mov rdi, msg_titulo
    call print_string
    call print_nl
    call print_nl

    ; 1. Abrir el dispositivo de video /dev/fb0
    sys_open fb_path, O_RDONLY, 0
    cmp rax, 0
    jl error_abrir          ; <-- Etiquetas sin punto (Globales en el archivo)
    mov r15, rax            ; Guardamos el File Descriptor en R15

    ; 2. Llamada IOCTL para obtener la información de la pantalla
    mov rdi, r15            ; File descriptor de /dev/fb0
    mov rsi, FBIOGET_VSCREENINFO
    mov rdx, fb_var_info    ; Puntero a nuestro buffer
    mov rax, SYS_IOCTL      ; Syscall 16
    syscall

    cmp rax, 0
    jl error_ioctl          ; <-- Etiquetas sin punto

    ; 3. Extraer e imprimir Resolución X (está en el offset 0)
    mov rdi, msg_xres
    call print_string
    xor rdi, rdi
    mov edi, dword [fb_var_info + 0]
    call print_int
    call print_nl

    ; 4. Extraer e imprimir Resolución Y (está en el offset 4)
    mov rdi, msg_yres
    call print_string
    xor rdi, rdi
    mov edi, dword [fb_var_info + 4]
    call print_int
    call print_nl

    ; 5. Extraer e imprimir Alto físico en mm (está en el offset 88)
    mov rdi, msg_ymm
    call print_string
    xor rdi, rdi
    mov edi, dword [fb_var_info + 88]
    call print_int
    call print_nl

    ; 6. Extraer e imprimir Ancho físico en mm (está en el offset 92)
    mov rdi, msg_xmm
    call print_string
    xor rdi, rdi
    mov edi, dword [fb_var_info + 92]
    call print_int
    call print_nl
    call print_nl

    ; 7. Cerrar archivo
    sys_close r15
    jmp fin_programa        ; <-- Etiquetas sin punto

error_ioctl:
    ; Si falla el ioctl, cerramos el archivo antes de salir
    sys_close r15

error_abrir:
    mov rdi, msg_error
    call print_string
    call print_nl

fin_programa:
    sys_exit 0              ; Syscall 60