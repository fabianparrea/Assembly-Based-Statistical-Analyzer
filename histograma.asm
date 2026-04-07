;Almacenar datos inicializados


section .data        

    notas_path      db "notas.txt",0      ;Asi se llamara el archivo de notas
    config_path     db "config.ini",0     ;Asi se llamara el archivo de configuracion

    ;Mensajes del programa (10 para salto de linea y un 0 para final del string)

    msg_title       db 10, "--- ESTADISTICAS ---",10,0
    msg_media       db "Media: ",0
    msg_mediana     db " | Mediana: ",0
    msg_moda        db " | Moda: ",0
    msg_std         db 10, "Desviacion Estandar: ",0
    msg_hist        db 10, "--- HISTOGRAMA ---",10,0

    msg_open_cfg_err    db "Error: no se pudo abrir config.ini.",10,0
    msg_read_cfg_err    db "Error: no se pudo leer config.ini.",10,0
    msg_cfg_err         db "Error: config.ini invalido.",10,0

    msg_open_notas_err  db "Error: no se pudo abrir notas.txt.",10,0
    msg_read_notas_err  db "Error: no se pudo leer notas.txt.",10,0
    msg_empty           db "Error: no se encontraron notas validas.",10,0

    ; separadores y simbolos usados en la impresion del reporte

    msg_newline     db 10,0
    sep_colon       db ": ",0
    sep_lpar        db " (",0
    sep_rpar_nl     db ")",10,0
    dash            db "-",0

    ; claves esperadas en el archivo config.ini

    key_color       db "COLOR:",0
    key_intervalo   db "INTERVALO:",0
    key_caracter    db "CARACTER:",0

    ; codigos ANSI para cambiar color en la terminal

    ansi_red        db 27,'[','3','1','m',0
    ansi_green      db 27,'[','3','2','m',0
    ansi_yellow     db 27,'[','3','3','m',0
    ansi_blue       db 27,'[','3','4','m',0
    ansi_reset      db 27,'[','0','m',0

    ; Se define un quadword (de 64 bits) que se usan luego en el programa

    ten_f64         dq 10.0
    hundred_f64     dq 100.0
    half_f64        dq 0.5

;Seccion para guardar buffers

section .bss
    config_buf      resb 2048     ;reservar 2048 bytes para el archivo config

    ; lectura por bloques/chunks para notas.txt
    notas_chunk     resb 4096   

    ; almacenamiento de notas
    ; 65536 notas maximas
    notes_arr       resd 65536   
    notes_sorted    resd 65536    ;esta es una copia para almacenar luego la mediana

    freq_arr        resd 101  ;array de frecuencias, ej freq_arr[82] = 2 (veces que ha aparecido)
    bins_arr        resd 128

    tmp_num         resb 64      ;buffer para convertir numeros a strings
    char_buf        resb 2       ; buffer para imprimir un caracter (1 byte caracter, 1 byte 0)

    color_value     resd 1    ;decimal que lee del color
    intervalo_value resd 1    ;decimal que lee del intervalo
    caracter_value  resb 1    ;caracter que lee para histograma

    ;Flags de validacion, si falta una debe haber un error de config

    found_color     resb 1   
    found_intervalo resb 1
    found_caracter  resb 1



    notes_count     resd 1 ;guarda para el contador de notas 32 bits
    bin_count       resd 1 ;cuantos intervalos tendra el histograma   (32 bits)
    sum_notes       resq 1 ;64 bits para guardar la suma de las notas

    mean_scaled10   resq 1   ; guarda la media *10
    median_scaled10 resq 1   ; guarda la mediana *10
    mode_value      resd 1   ; guarda el valor de la moda
    std_scaled100   resq 1   ; desviacion estandar*100
    mean_f64        resq 1   ;guarda un float de 64 bits de la media

    line_low        resd 1   ;limite inferior y superior de cada bin
    line_high       resd 1

    ; estado del parser streaming de notas
    cur_num         resd 1   ;numero que se va construyendo mientras se lee
    in_number       resb 1   ; booleano si se esta leyendo un numero actualmente
    line_candidate  resd 1   ;ultimo numero que se haya leido en el parser
    has_candidate   resb 1   ; booleano si la linea leida tenia una nota valida

section .text   
global _start

; ==========================================
; Punto de entrada
; ==========================================
_start:
    mov byte [char_buf], 0     ;asegurarse dejar el buffer de caracter en un estado conocido
    mov byte [char_buf+1], 0

    call leer_config    ;llamar a subrutina de leer config, cuando termina devuelve un valor en el registro eax
    cmp eax, 0         ; si eax == 0 todo salio bien
    je .cfg_ok         ;entonces saltar a .cfg_ok
    cmp eax, 1         ; si eax ==1 salio mal
    je .cfg_read_fail  ; entonces ir a cfg_read_fail
    cmp eax, -2        ; si eax == -2 entonces el archivo se leyo pero es invalido
    je .cfg_invalid
    jmp .cfg_open_fail ;si no pasa nada de esto pues es que no se pudo abrir el archivo de config

.cfg_ok:
    call leer_notas      ; ir a la subrutina que procesa las notas 
    cmp eax, 0           ;si eax == 0 todo salió bien
    je .notas_ok
    cmp eax, 1          ; si eax == 1 entonces se leyo algo mal
    je .notas_read_fail
    jmp .notas_open_fail  ; si no paso nada de lo pasado entonces el archivo no esta

.notas_ok:
    mov eax, [notes_count]    ; se carga en eax el total de notas encontradas
    test eax, eax             ; aqui se pregunta si eax == 0
    jz .sin_datos             ; si es 0 entonces saltar a .sin_datos


    ; si habian datos en notas entonces ir secuencialmente a todas estas subrutinas

    call calcular_estadisticas
    call calcular_histograma
    call imprimir_reporte


    mov eax, 60       ;poner eax en 60, para posteriormente hacer syscall = 60  (exit)
    xor edi, edi     ;poner edi = 0 que implica exito
    syscall         ;ejecutar llamada a sistema 

.cfg_open_fail:
    mov rsi, msg_open_cfg_err   ;cargar el mensaje de error de config en rsi
    call print_cstr             ; ir a print_cstr
    jmp .exit_fail             ;luego ir a exit_fail

.cfg_read_fail:
    mov rsi, msg_read_cfg_err    ;cargar el mensaje de error de read de config en rsi
    call print_cstr
    jmp .exit_fail

.cfg_invalid:
    mov rsi, msg_cfg_err     ;cargar mensaje de error por config invalido
    call print_cstr
    jmp .exit_fail

.notas_open_fail:                 ;cargar mensaje de error de open de notas en rsi
    mov rsi, msg_open_notas_err
    call print_cstr
    jmp .exit_fail
 
.notas_read_fail:                ;cargar mensaje de error de read de notas en rsi
    mov rsi, msg_read_notas_err
    call print_cstr
    jmp .exit_fail

.sin_datos:                ;cargar mensaje de error por no datos en rsi y luego cae a exit_fail por lo que no hace falta hacer el jmp
    mov rsi, msg_empty
    call print_cstr

.exit_fail:           ; syscall = 60 de exit y deja edi = 1 implicando fail
    mov eax, 60
    mov edi, 1
    syscall

; ==========================================
; leer_config
; Retorna:
;   eax = 0  -> ok
;   eax = -1 -> open fail
;   eax = 1  -> read fail
;   eax = -2 -> config invalido
; ==========================================
leer_config:

    ;guardar estos registros en la pila para no dañarlos

    push rbx      ;puntero para recorrer el buffer
    push r12      ; file descriptor del archivo
    push r13      ; cantidad de bytes leidos

    ;poner en 0 las banderas de si se encontro cada clave

    mov byte [found_color], 0 
    mov byte [found_intervalo], 0
    mov byte [found_caracter], 0


    mov eax, 2      ;syscall =2 (open)
    mov rdi, config_path  ; poner en rdi el nombre del archivo de config
    xor esi, esi  ; esi= 0  modo read only
    xor edx, edx   
    syscall
    test rax, rax   ;si open sale bien devuelve un numero no negativo
    js .open_fail  ;si el numero en rax es negativo entonces hubo un fail
    mov r12, rax  ;se pone el file descriptor en r12


    ;leer archivo
    mov eax, 0  ;poner en eax = 0 (read)
    mov rdi, r12  ;poner en rdi el file descriptor (archivo abierto)
    mov rsi, config_buf  ;buffer donde se guarda todo lo leido
    mov edx, 2047   ;maximo de bytes a leer -1 (el correspondiente a 0)
    syscall
    test rax, rax  ;revisar si read fallo
    js .read_fail_close   ;si es negativo el rax entonces fallo
    mov r13, rax            ;guarda la cantidad de bytes leidos
    mov byte [config_buf + r13], 0   ;agregar un 0 luego de todo lo leido para poder leer y saber que el 0 implica que ya termino

    mov eax, 3      ; syscall = 3 (close)
    mov rdi, r12    ; poner en rdi el file descriptor
    syscall

    mov rbx, config_buf   ;empezar a recorrer el buffer con toda la info (rbx va apuntando y se va moviendo en toda la info que esta en el buffer)

.parse_line:
    mov al, [rbx]   ;lee el byte actual del buffer
    test al, al     ;preguntar si ese byte es 0
    jz .validate    ;si lo es pues ya termino de leer el archivo

.skip_ws:      ;saltar espacios y lineas vacias

    ;la idea aqui es que compara al que es el byte actual que lee y ve si es un espacio, si es un tab (9), si es un salto de linea (10), si es un retorno de carro (13), si es un comentario

    mov al, [rbx]     
    cmp al, ' '    
    je .inc_ws      ;hacen jump en donde se hace la logica de saltar
    cmp al, 9
    je .inc_ws      ;hace un jump igual para saltar
    cmp al, 10
    je .next_char   ;hace un jump a la logica donde se salta de linea
    cmp al, 13      
    je .next_char  ;hace un jump a la logica donde se salta de linea
    cmp al, '#'
    je .line_done   ;salta a linea hecha si se encuentra ya con un comentario
    jmp .check_keys   ;si no fue nada de eso entonces salta a .check_keys

.inc_ws:           ;avanzar el cursor si se ve un espacio
    inc rbx
    jmp .skip_ws

.next_char:     ; si se ve un /n o /r avanzar y volver al loop principal
    inc rbx
    jmp .parse_line

.check_keys:  
    mov rdi, rbx    ; rdi = texto actual
    mov rsi, key_color  ;rsi = color=
    call starts_with   ;llama a la subrutina starts_with
    test eax, eax      ;si coincide entonces eax =1
    jz .check_intervalo  ; si es 0 no coinciden y va entonces a checkear intervalo

    lea rdi, [rbx + 6]         ;rbx +6 apunta al valor de color que se quiere
    call parse_uint_line      ;lee un numero entero desde ahi
    test eax, eax           ;revisa el resultado
    jle .line_done          ; si el numero es menor o igual a 0 no lo acepta
    mov [color_value], eax         ; guardar el valor de color
    mov byte [found_color], 1      ;aparecio color
    jmp .line_done                 ;linea lista

.check_intervalo:      ;misma idea que con color
    mov rdi, rbx       
    mov rsi, key_intervalo
    call starts_with
    test eax, eax
    jz .check_caracter

    lea rdi, [rbx + 10]   ;10 caracteres de intervalo=
    call parse_uint_line
    test eax, eax
    jle .line_done
    mov [intervalo_value], eax
    mov byte [found_intervalo], 1
    jmp .line_done

.check_caracter:    ;misma idea 
    mov rdi, rbx
    mov rsi, key_caracter
    call starts_with
    test eax, eax
    jz .line_done

    lea rdi, [rbx + 9]   ;9 caracteres de caracter=
    call parse_char_line
    test al, al
    jz .line_done
    mov [caracter_value], al
    mov byte [found_caracter], 1

.line_done:
.find_eol:    ;encontrar end of line
    mov al, [rbx]      
    test al, al       ;ver si este al es 0
    jz .validate    ; si es 0 entonces termino
    cmp al, 10      ;si encuentra un 10 ya hay un salto de linea
    je .after_eol    ;jump al salto de linea
    inc rbx      ;si no era ninguno de los dos entonces que siga buscando el end of line recursivamente
    jmp .find_eol

.after_eol:   
    inc rbx    ;moverse al primer caracter de la siguiente linea
    jmp .parse_line   ;volver a leer la siguiente linea

.validate:      ;validar que ya haya terminado entonces la lectura y haya leido todo lo que se ocupa
    mov al, [found_color]    ;cargar bandera de found color
    test al, al                ; 0 si no se encontro, 1 si si
    jz .cfg_bad

    mov al, [found_intervalo]   ;misma idea
    test al, al
    jz .cfg_bad

    mov al, [found_caracter]    ;misma idea
    test al, al
    jz .cfg_bad

    mov eax, [color_value] ;cargar el valor del color dado
    cmp eax, 1            ;comparar contra 1
    jb .cfg_bad           ;esta por debajo
    cmp eax, 4            ;comparar contra 4
    ja .cfg_bad           ;esta por encima

    mov eax, [intervalo_value]    ;misma idea de validar que este en rango
    cmp eax, 1
    jb .cfg_bad
    cmp eax, 100
    ja .cfg_bad

    mov al, [caracter_value]        ;compara que el caracter value no este vacio
    test al, al
    jz .cfg_bad

    xor eax, eax        ;ya esto hecho poner eax en 0
    jmp .done            

.cfg_bad:          
    mov eax, -2           ;poner eax de forma que le diga que el config estaba mal
    jmp .done

.read_fail_close:        ;el read fallo pero el archivo se abrio entonces hay que cerrarlo
    mov eax, 3        ;syscall close
    mov rdi, r12     ;file descriptor en close
    syscall
    mov eax, 1        ;syscall = 1 error de lectura
    jmp .done

.open_fail:
    mov eax, -1         ;-1 no se pudo abrir el archivo

.done:
    pop r13            ;volver a dejar la pila como estaba
    pop r12
    pop rbx
    ret             ;volver a start, quien llamo esta funcion

; ==========================================
; leer_notas
; Retorna:
;   eax = 0  -> ok
;   eax = -1 -> open fail
;   eax = 1  -> read fail
; ==========================================
leer_notas:
    push rbx   ;cursor dentro del bloque leído
    push r12   ;cursor dentro del bloque leído
    push r13   ;cantidad de bytes leídos en el chunk
    push r14   ;dirección del final del chunk
    push r15   

    lea rdi, [freq_arr]   ;poner en rdi la direccion inicial de este array 
    mov ecx, 101          ;pongo ecx = 101 referente a que el loop se va a hacer 101 veces porque solo hay notas de 0 a 100
    xor eax, eax          ;eax = 0
.clear_freq:
    mov dword [rdi], eax      ;escribir 0 en la posicion actual
    add rdi, 4               ;avanzar un elemento, cada elemento en el array de freq es un dword, es decir, 4 bytes
    loop .clear_freq


    ;inicializar en 0 cada contador y estado del parser
    mov qword [sum_notes], 0
    mov dword [notes_count], 0

    mov dword [cur_num], 0
    mov byte [in_number], 0
    mov dword [line_candidate], 0
    mov byte [has_candidate], 0

    mov eax, 2    ; syscall =2 es open
    mov rdi, notas_path  ; busca el archivo llamado notas.txt
    xor esi, esi     ;esi = 0 solo lectura
    xor edx, edx
    syscall
    test rax, rax      
    js .open_fail   ; si rax es negativo hubo error de open
    mov r12, rax  ;guardar el file descriptor

.read_loop:
    mov eax, 0    ;syscall = 0 (read)
    mov rdi, r12     ;file descriptor en dri
    mov rsi, notas_chunk          ;poner lo que se lea en este buffer
    mov edx, 4096                 ;leer hasta 4096 bytes
    syscall

    ;revisar si el read fallo
    test rax, rax     
    js .read_fail_close
    test rax, rax
    jz .eof


    mov r13, rax     ;guardar cantidad de bytes leidos en rax
    lea rbx, [notas_chunk]        ;rbx la posicion del inicio del buffer
    lea r14, [notas_chunk + r13]      ;poner en r14 el final del chunk

.process_chunk:
    cmp rbx, r14  
    jae .read_loop   ;si rbx es mayor o igual a r14 ya se termino de procesar ese chunk, que vaya al siguiente de ser necesario

    mov al, [rbx]     ;procesar cada byte, guardarlo en al

    cmp al, '0'     ;revisar que el valor de al este entre 0 y 9
    jb .not_digit
    cmp al, '9'
    ja .not_digit

    mov dl, al   ;convertir ascii a numero restandole '0'
    sub dl, '0'

    cmp byte [in_number], 0    ;comparar la bandera de in_number, es 0 si no se estaba leyendo un numero
    jne .append_digit          

    mov byte [in_number], 1   ;aqui se empieza a leer un numero nuevo, se pone la bandera en 1
    movzx eax, dl            ;copiar el valor del digito en eax
    mov [cur_num], eax        ;guardar ese valor en cur_num
    jmp .advance            

.append_digit:    ;Esto implementa la construcción de números de varios dígitos.
    mov eax, [cur_num]      ;se pone en eax el current number
    imul eax, eax, 10       ;se multiplica eax*10
    movzx edx, dl           ;se pone en edx el nuevo current number
    add eax, edx            ; se suman ambos digitos con el truco de eax*10 + edx
    mov [cur_num], eax      ;ahora cur_num es eax listo con los 2 digitos
    jmp .advance

.not_digit:         ;si no era un digito
    cmp al, 10
    je .newline       ;si es un salto de linea entonces vaya a .newline
    cmp al, 13
    je .advance         ;si es retorno de carro entonces seguir

    cmp al, ' '        ;si es un espacio en blanco o tab entonces se trata en .ws
    je .ws
    cmp al, 9
    je .ws

    ; cualquier otro char invalida un candidato previo de esa linea
    ;ejemplo: un Fulano 85abc ya no vale por ese abc del final
    mov byte [in_number], 0
    mov byte [has_candidate], 0
    jmp .advance

.ws:
    cmp byte [in_number], 0   ;si se venia leyendo un numero =1
    je .advance            ; si no se venia leyendo un numero todo bien, seguir
    mov eax, [cur_num]          ;en eax pongo el valor de ese digito
    mov [line_candidate], eax   ;guardar ese numero como candidato de linea
    mov byte [has_candidate], 1   ;pongo que tengo un candidato en el flag
    mov byte [in_number], 0       ; no vengo leyendo un numero
    jmp .advance

.newline:
    cmp byte [in_number], 0     ; si in_number no estaba leyendo numero (0)
    je .maybe_commit            ;ir a maybe_commit
    mov eax, [cur_num]          ;si si habia numero, mover el cur_num a eax
    mov [line_candidate], eax     ;moverlo a line_candidate
    mov byte [has_candidate], 1    ;hay nuevo candidato
    mov byte [in_number], 0         ;ya se terminó de leer numero

.maybe_commit:                        ;aqui basicamente si hay un candidato de nota, entonces aqui se guarda
    cmp byte [has_candidate], 0
    je .reset_line      ;si no hay candidato entonces no se guarda nada y se limpia el estado

    mov eax, [line_candidate]     ;si si
    cmp eax, 100                  ;validar que no sea mayor a 100
    ja .reset_line                   

    mov ecx, [notes_count]    ;revisar que la cantidad de notas sea menor a 65 536, si ya esta por encima o igual entonces no se guarda
    cmp ecx, 65536
    jae .reset_line

    mov [notes_arr + rcx*4], eax      ;guardar la nota en el arreglo de notas
    mov [notes_sorted + rcx*4], eax    ;tambien se guarda en la copia de la mediana
    inc dword [notes_count]            ;aumentar el contador de notas

    movsxd rdx, eax               ;convertir el numero que esta en eax a 64 bits en vez de 32 bits para poder sumarlo en sum_notes
    add qword [sum_notes], rdx    ;suma la nota al acumulado total
    inc dword [freq_arr + rax*4]   ;aumenta la frecuencia de esa nota en el array de freq

.reset_line:                          ;aqui se limpia todo para seguir con otra linea
    mov dword [cur_num], 0
    mov byte [in_number], 0
    mov dword [line_candidate], 0
    mov byte [has_candidate], 0
    jmp .advance

.advance:         ;se mueve el puntero al siguiente byte del archivo y sigue procesando
    inc rbx
    jmp .process_chunk

.eof:                                                                     
    ; si el archivo no termina en newline, procesar la ultima linea
    cmp byte [in_number], 0          ;ya no quedan mas bytes en el archivo, termina   
    je .eof_commit_check
    mov eax, [cur_num]    ;Estaba leyendo un número justo cuando se acabó el archivo; lo guardo como candidato
    mov [line_candidate], eax
    mov byte [has_candidate], 1
    mov byte [in_number], 0

.eof_commit_check:                ;guardar la ultima linea pendiente, si no habia candidato pendiente ya no hay nada que guardar
    cmp byte [has_candidate], 0
    je .close_ok

    mov eax, [line_candidate]   ;validar que sea menor o igual que 100
    cmp eax, 100
    ja .close_ok

    mov ecx, [notes_count]     ;validar limite de cantidad de notas 
    cmp ecx, 65536
    jae .close_ok

    mov [notes_arr + rcx*4], eax   ;guarda la ultima nota pendiente de la misma forma que en maybe:commit
    mov [notes_sorted + rcx*4], eax
    inc dword [notes_count]

    movsxd rdx, eax
    add qword [sum_notes], rdx
    inc dword [freq_arr + rax*4]

.close_ok:     
    mov eax, 3     ;syscall close
    mov rdi, r12    ;r12 tiene el file descriptor
    syscall
    xor eax, eax     ;pone eax en 0
    jmp .done       ;ir a done

.read_fail_close:     
    mov eax, 3  ;syscall close
    mov rdi, r12   ;file descriptor
    syscall
    mov eax, 1     ;syscall fallo de lectura
    jmp .done

.open_fail:            ;syscall -1 solo devuelve eso pues no abrio nada
    mov eax, -1

.done:                  ;restaurar registros y volver a start
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; ==========================================
; calcular_estadisticas
; ==========================================
calcular_estadisticas:       ;guardar registros que se van a usar aqui
    push rbx         
    push rcx
    push rdx
    push r12
    push r13

    ; media real              siendo suma de notas / cantidad de notas 
    mov rax, [sum_notes]         ;rax = suma de notas
    cvtsi2sd xmm0, rax           ;Convierte ese entero a double y lo pone en xmm0
    mov eax, [notes_count]       ;eax = cantidad de notas 
    cvtsi2sd xmm1, rax           ; convierte ese entero a double y lo pone en xmm1
    divsd xmm0, xmm1               ;hace la division
    movsd [mean_f64], xmm0        ;guarda esa media real en memoria

    ; mean_scaled10 con redondeo
    mulsd xmm0, [ten_f64]      ;xmm0 *10
    addsd xmm0, [half_f64]     ;se le suma 0,5
    cvttsd2si rax, xmm0        ;convertir ese double a entero truncado, quitandole el decimal
    mov [mean_scaled10], rax   ;guardar el resultado

    ; ordenar notes_sorted
    mov ecx, [notes_count]   ;cargar la cantidad de notas en ecx
    cmp ecx, 1               ;si hay 0 o 1 notas no hace falta ordenar
    jle .median_part         ;Si hay 1 o menos, brincas directo a calcular mediana
    mov r12d, 1              ;Aquí se arranca el índice externo del algoritmo de ordenamiento.
 

;Va agarrando cada elemento y lo inserta en su posición correcta entre los anteriores.

.outer_sort:      
    cmp r12d, ecx             ;si llego al final del arreglo deja de ordenar
    jge .median_part
    mov eax, [notes_sorted + r12*4]   ;carga la nota actual que se quiere insertar
    mov r13d, r12d      ;se usa r13d como indice externo para mover esa nota a la izquierda si hace falta

.inner_sort:           ;; mover la nota actual hacia la izquierda hasta encontrar su lugar correcto
    cmp r13d, 0 
    jle .insert_key
    mov edx, [notes_sorted + r13*4 - 4]
    cmp edx, eax
    jle .insert_key
    mov [notes_sorted + r13*4], edx
    dec r13d
    jmp .inner_sort

.insert_key:            ;; mover la nota actual hacia la izquierda hasta encontrar su lugar correcto
    mov [notes_sorted + r13*4], eax
    inc r12d
    jmp .outer_sort

.median_part: ; decidir si la cantidad de notas es par o impar para calcular la mediana
    mov eax, [notes_count]
    test eax, 1
    jnz .median_odd

    ; par
    mov ecx, eax
    shr ecx, 1
    mov eax, [notes_sorted + rcx*4 - 4]
    mov edx, [notes_sorted + rcx*4]
    add eax, edx
    imul eax, 10
    cdq
    mov ecx, 2
    idiv ecx
    movsxd rax, eax
    mov [median_scaled10], rax
    jmp .mode_part

.median_odd:         ; tomar la nota central del arreglo ordenado cuando hay cantidad impar
    mov ecx, eax
    shr ecx, 1
    mov eax, [notes_sorted + rcx*4]
    imul eax, 10
    movsxd rax, eax
    mov [median_scaled10], rax

.mode_part:               ; inicializar variables para buscar la nota con mayor frecuencia
    xor ebx, ebx
    xor r12d, r12d
    xor r13d, r13d

.mode_loop:                ; recorrer freq_arr de 0 a 100 para encontrar la moda
    cmp ebx, 101
    jge .std_part
    mov eax, [freq_arr + rbx*4]
    cmp eax, r12d
    jle .next_mode
    mov r12d, eax
    mov r13d, ebx

.next_mode:              ; avanzar a la siguiente nota posible en la busqueda de la moda
    inc ebx
    jmp .mode_loop

.std_part:                      ; guardar la moda y preparar el calculo de desviacion estandar
    mov [mode_value], r13d

    xorpd xmm2, xmm2
    movsd xmm7, [mean_f64]

    xor ebx, ebx
    mov ecx, [notes_count]

.std_loop:                      ; guardar la moda y preparar el calculo de desviacion estandar
    cmp ebx, ecx
    jge .std_finish
    mov eax, [notes_arr + rbx*4]
    cvtsi2sd xmm0, rax
    movapd xmm1, xmm0
    subsd xmm1, xmm7
    mulsd xmm1, xmm1
    addsd xmm2, xmm1
    inc ebx
    jmp .std_loop

.std_finish:                   ; terminar la formula de desviacion estandar y guardarla escalada por 100
    mov eax, [notes_count]
    cvtsi2sd xmm3, rax
    divsd xmm2, xmm3
    sqrtsd xmm2, xmm2
    mulsd xmm2, [hundred_f64]
    addsd xmm2, [half_f64]
    cvttsd2si rax, xmm2
    mov [std_scaled100], rax

    pop r13
    pop r12
    pop rdx
    pop rcx
    pop rbx
    ret

; ==========================================
; calcular_histograma
; ==========================================
calcular_histograma:
    push rbx      ;guardar registros que se van a usar en esta funcion
    push rcx
    push rdx

    mov eax, 99       ;calcula cuantos bins se ocupan
    xor edx, edx
    mov ecx, [intervalo_value]     ;cargar el intervalo
    div ecx                         ;divide 99/ intervalo
    inc eax                         ;se suma 1
    mov [bin_count], eax         ;eax que es bin count va a bin_count

    lea rbx, [bins_arr]         ;rbx apunta al inicio del arreglo de bins
    mov ecx, 128               ;se limpia todo el arreglo 
    xor eax, eax       ;eax = 0
.clear_bins:
    mov dword [rbx], eax     ;aqui escribe 0 en el bin actual y se va moviendo loopeado 128 veces
    add rbx, 4
    loop .clear_bins

    xor ebx, ebx             ;ebx = 0
    mov ecx, [notes_count]      ; ecx va a aser la cantidad de notas que hay que revisar

.fill_bins:                  
    cmp ebx, ecx         ;pregunta si ya se recorrieron todas las notas, si si entonces ir a done
    jge .done

    mov eax, [notes_arr + rbx*4]   ;si no carga nota actual
    test eax, eax                  ;si la nota es 0 brinca a bin de zero
    jz .bin_zero 

    dec eax                  ;aqui es el caso general mayor a 0  (resta 1 a la nota)
    xor edx, edx          ;edx = 0
    div dword [intervalo_value]         ;se divide (nota -1)/intervalo
    jmp .inc_bin            

.bin_zero:
    xor eax, eax           ;eax = 0 (indice del bin será 0)

.inc_bin:     
    cmp eax, [bin_count]       ;preguntar si el indice calculado es menor a la cantidad de bins
    jb .inc_ok      ; si esta dentro del rango todo bien
    mov eax, [bin_count]       ;mandar la nota al ultimo rango
    dec eax

.inc_ok:
    inc dword [bins_arr + rax*4]
    inc ebx
    jmp .fill_bins

.done:               ;restaurar registros y volver
    pop rdx
    pop rcx
    pop rbx
    ret

; ==========================================
; imprimir_reporte
; ==========================================
imprimir_reporte:
    push rbx       ;guarda registros que se van a usar
    push rcx
    push rdx
    push r12
    sub rsp, 8           ;baja la pila 8 bytes para mantener la pila alineada a la hora de hacer calls

    mov rsi, msg_title     ;poner en rsi el mensaje de titulo
    call print_cstr        ;llamar la subrutina de printear

    mov rsi, msg_media           ;imprimir mensaje de media
    call print_cstr
    mov rax, [mean_scaled10]  ;cargar la media escalada *10
    mov ecx, 1            ;indicarle a print_fixed_scale que quiero 1 decimal poniendole a ecx=1
    call print_fixed_scaled

    mov rsi, msg_mediana      ;misma idea que con la media
    call print_cstr
    mov rax, [median_scaled10]
    mov ecx, 1
    call print_fixed_scaled

    mov rsi, msg_moda     ;mensaje de moda
    call print_cstr
    mov eax, [mode_value]       
    imul eax, eax, 10      ;se multiplica la moda *10 para usar la misma rutina de impresion a pesar de que la moda sea un entero
    movsxd rax, eax      ;extender de 32 a 64 bits
    mov ecx, 1
    call print_fixed_scaled      ;printear moda

    mov rsi, msg_std       ;mensaje de desviacion estandar
    call print_cstr
    mov rax, [std_scaled100]     
    mov ecx, 2
    call print_fixed_scaled  ;printear std con 2 decimales

    mov rsi, msg_newline    ;imprimir una linea extra vacia porque se viene el histograma
    call print_cstr

    mov rsi, msg_hist ;imprimir titulo de histograma
    call print_cstr
    call print_color_code       ;llamar a la funcion que mira color_value y escribe el codigo ansi del color correspondiente

    xor ebx, ebx        ;prepara loop de bins en 0, ebx siendo cada uno de los bins

.bin_loop:  
    cmp ebx, [bin_count]     ;ya se imprimieron todos los bins?
    jge .after_bins           ;jump if greater or equal (salir del loop)

    ; calcular el inicio del rango del bin actual
    cmp ebx, 0
    jne .low_nonzero
    xor eax, eax
    jmp .save_low

.low_nonzero:    ;se calcula limite inferior de los intervalos siendo bin*intervalo +1
    mov eax, ebx
    imul eax, [intervalo_value]
    inc eax

.save_low:                      ;lo guarda el limite inferior
    mov [line_low], eax

    ; high = min((idx+1)*intervalo, 100)  calcular limite superior
    mov eax, ebx
    inc eax
    imul eax, [intervalo_value]
    cmp eax, 100
    jle .save_high
    mov eax, 100

.save_high:                 ;lo guarda el limite superior
    mov [line_high], eax

    mov eax, [line_low]   ;imprimir los rangos de bin         de forma : line low-line high :
    call print_uint2       ;imprime el numero con 2 digitos si hace falta esta funcion
    mov rsi, dash
    call print_cstr
    mov eax, [line_high] 
    call print_uint2
    mov rsi, sep_colon
    call print_cstr

    mov edx, [bins_arr + rbx*4] ;cargar cuantos elementos tiene ese bin

.char_repeat:           ;imprime la barra caracter por caracter
    test edx, edx
    jz .count_part                ;aqui salta si ya no queda ninguno mas por imprimir, el contador llego a 0 
    mov al, [caracter_value]        ;aqui imprime un solo caracter de la barra
    mov [char_buf], al              ;pongo el caracter en el char_buff
    mov byte [char_buf+1], 0       ;terminador nulo para que sea string
    mov rsi, char_buf               ;apunta a ese string
    call print_cstr                 ;printea
    dec edx                         ;reduce el contador de caracteres pendientes
    jmp .char_repeat              ;loopea

.count_part:           ;imprime el conteo entre parentesis
    mov rsi, sep_lpar                    ;aqui se imprime el : (conteo de bins)
    call print_cstr
    mov eax, [bins_arr + rbx*4]
    call print_uint32
    mov rsi, sep_rpar_nl
    call print_cstr

    inc ebx
    jmp .bin_loop

.after_bins:              ;se resetea el color de terminal para que no se quede asi 
    mov rsi, ansi_reset
    call print_cstr

    add rsp, 8    ;deshago el sub rsp 8 del inicio
    pop r12       ;restauro estos registros
    pop rdx
    pop rcx
    pop rbx
    ret ;volver a quien llamo la funcion

; ==========================================
; Helpers de impresion que estoy usando 
; ==========================================
print_cstr:          ;esta es la funcion que llamo siempre que tengo que imprimir algo como tal
    push rdi       ;guardo estos registros porque los voy a modificar
    push rdx
    sub rsp, 8   ;ajustar la pila 

    mov rdi, rsi ;copiar a rdi el string que se quiere imprimir
    call strlen     ;funcion que cuenta cuantos caracteres tiene el string
    mov rdx, rax     ;rax = longitud del string cuando vuelve en rdx que ocupa el syscall
    mov eax, 1    ;syscall write 
    mov edi, 1   ;esto significa stdout 
    syscall
 
    add rsp, 8   ;restaura todo y vuelve
    pop rdx
    pop rdi
    ret

strlen:                  ;cantidad de caracteres
    xor rax, rax ;rax sera la cantidad de caracteres
.len_loop:
    cmp byte [rdi + rax], 0     ;rdi = inicio del string, rax = cuantos caracteres lleva contados 
    je .done              ; si el caracter acutal es 0 entonces ya termino
    inc rax         ;si no se suma 1 a rax
    jmp .len_loop        ;vuelve al loop
.done:
    ret       ;vuelve a la funcion que lo llamo

print_uint32:         ;imprime un entero sin signo que viene en eax
    push rbx        ;porque no puede imprimir el numero entero de una, la idea es pasarlo a texto y ahora usar la funcion de siempre de print_cstr
    push rcx
    push rdx
    push rsi
    sub rsp, 8

    lea rsi, [tmp_num + 63]   ;apuntar al final del buffer temporal que usamos aqui
    mov byte [rsi], 0         ;le pone un 0 al final
    mov ecx, 10               ;se divide entre 10 porque se le saca un decimal

    cmp eax, 0       ;caso especial de numero 0
    jne .conv

    dec rsi            ;si es 0 se construye el string 0 y listo
    mov byte [rsi], '0'
    jmp .out

.conv:   ;conversion normal
    xor edx, edx
.loop:         ;se divide entre 10 entonces el valor de cada digito queda en cociente y residuo  
    div ecx  
    add dl, '0'       ;convierte el residuo en string
    dec rsi 
    mov [rsi], dl
    xor edx, edx
    test eax, eax
    jnz .loop

.out:
    call print_cstr   ;imprimir string final

    add rsp, 8       ;devolver todo como estaba
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

print_uint2: ;imprime rangos de numeros pequeño en formato de 2 digitos, tipo 01, 02, 03 ...
    push rbx
    push rcx
    push rdx

    cmp eax, 100
    jne .not100

    mov rsi, tmp_num         ;caso especial de 100, en este caso simplemente mete en rsi manualmente el 100 e imprime
    mov byte [rsi], '1'
    mov byte [rsi+1], '0'
    mov byte [rsi+2], '0'
    mov byte [rsi+3], 0
    call print_cstr
    jmp .done

.not100:               ;todos los demas casos
    xor edx, edx       ;eddx=0
    mov ecx, 10      ;divide el numero/10 asi queda: eax=decenas, edx unidades
    div ecx
    mov bl, al           ;guarda decenas
    add bl, '0'          ; lo convierte a ascii
    add dl, '0'          ;convierte la unidad a ascii
    mov rsi, tmp_num   ;arma el string en tmp_num
    mov [rsi], bl
    mov [rsi+1], dl
    mov byte [rsi+2], 0
    call print_cstr   ;printea

.done:               ;si ya termino devuelve los registros como estaban y vuelve a quien llamo la funcion
    pop rdx
    pop rcx
    pop rbx
    ret

print_fixed_scaled:                ;imprime numero con decimal que dicta ecx
    ; RAX = entero escalado, ECX = cantidad de decimales (1 o 2)
    push rbx
    push rdx
    push r8
    push r9
    sub rsp, 8

    mov r8, rax ;caso 1 decimal
    cmp ecx, 1
    jne .two_dec   ;si es de 2 decimales ir a two_dec

    mov rax, r8     ;divide entre 10 asi en cociente queda la parte entera y en residuo queda el decimal
    xor rdx, rdx
    mov rbx, 10
    div rbx
    mov r9d, edx

    call print_uint32      ;llama a la funcion para imprimir parte entera
    mov rsi, tmp_num        ;esto imprime el punto y el decimal
    mov byte [rsi], '.'
    mov dl, r9b
    add dl, '0'
    mov [rsi+1], dl
    mov byte [rsi+2], 0
    call print_cstr
    jmp .done

.two_dec:                ;caso de 2 decimales 
    mov rax, r8
    xor rdx, rdx
    mov rbx, 100       ;misma idea pero dividiendo entre 100
    div rbx
    mov r9d, edx

    call print_uint32 ;imprime parte entera

    mov rsi, tmp_num        ;imprime el punto y la parte decimal
    mov byte [rsi], '.'
    mov eax, r9d
    xor edx, edx
    mov ebx, 10    ;vuelve a dividir entre 10 para separar los dos digitos del decimal
    div ebx
    add al, '0'
    add dl, '0'
    mov [rsi+1], al
    mov [rsi+2], dl
    mov byte [rsi+3], 0
    call print_cstr          

.done:        ;devuelve todo como estaba
    add rsp, 8
    pop r9
    pop r8
    pop rdx
    pop rbx
    ret

print_color_code:               ;mira el valor de color_value y decide que color de ansi imprimir
    mov eax, [color_value]           ;cada comparacion con cada color
    cmp eax, 1
    je .red
    cmp eax, 2
    je .green
    cmp eax, 3
    je .yellow
    cmp eax, 4
    je .blue
    ret             ;si no es ninguno volver y no imprime nada

.red:                               ;si es cada color se manda en rsi el valor ansi del color que entiende que es
    mov rsi, ansi_red
    jmp print_cstr

.green:
    mov rsi, ansi_green
    jmp print_cstr

.yellow:
    mov rsi, ansi_yellow
    jmp print_cstr

.blue:
    mov rsi, ansi_blue
    jmp print_cstr

; ==========================================
; Helpers de parseo de los documentos para no meter todo esto en la seccion de leer config y llamarlas simplemente cuando se ocupen
; ==========================================
starts_with:           ;revisa que empiece el config con los valores que deben empezar de color=, intervalo=, caracter=
    push rbx
.sw_loop:
    mov al, [rsi]      ;texto a comparar en rsi
    test al, al     ;preguntar si el caracter es 0 
    jz .yes          ;si llego al final de este "prefijo" entonces todo coincidio
    mov bl, [rdi]    ;texto a revisar 
    cmp bl, al ;aqui compara ambos textos
    jne .no    ;si no son pues salta a que no son
    inc rdi       ;avanza a siguiente caracter del prefijo sino para seguir comparando
    inc rsi
    jmp .sw_loop    ;loopeado este proceso

.yes:         ; si si coincide devuelve un 1 en eax
    mov eax, 1
    pop rbx
    ret

.no:          ;si no devuelve un 0 en eax 
    xor eax, eax
    pop rbx
    ret

parse_uint_line:    ;esto sirve para leer el valor de color y el valor de caracter 
    xor eax, eax    ;poongo eax=0 aqui pongo el numero al final que parsea

.pul_skip:    ;ignora espacios o tabs que hayan
    mov dl, [rdi] ;carga caracter actual
    cmp dl, ' '     ;compara dl con un espacio o un 9 de tab y si si entonces skipea esto
    je .inc_skip
    cmp dl, 9
    je .inc_skip
    jmp .pul_loop    ;si no era nada de esto entonces ahi si empieza a leer el numero

.inc_skip:        ;simplemente mover el puntero de rdi y seguir revisando
    inc rdi
    jmp .pul_skip

.pul_loop:      
    mov dl, [rdi]   ;carga caracter ctual
    cmp dl, '0'     ;revisa que no haya llegado al final
    jb .pul_done
    cmp dl, '9'         ;si es digito esta por encima de 9 termina el parseo
    ja .pul_done
    imul eax, eax, 10     ;si si es digito multiplica por 10
    sub dl, '0'          ;convierte de ascii a numero
    movzx edx, dl       ;poner el digito en edx
    add eax, edx   ;se suma al acumulado donde se va a formar el numero como tal 
    inc rdi   ;avanzar siguiente caracter
    jmp .pul_loop         ;sigue para formar el numero total, la idea de como lo forma es asi; numero total (eax) = numero *10 +digito

.pul_done:        ;si ya termino entonces volver a quien lo llamo la funcion con el numero en eax
    ret

parse_char_line:     ;busca el primer caracter util de la linea 
.skip:
    mov al, [rdi]      ;carga caracter actual
    test al, al      ;pregunta si es 0
    jz .none       ;si es 0 entonces no encontro caracter valido
    cmp al, 10     ;si hay salto de linea tampoco es caracter valido
    je .none
    cmp al, 13 ;si hay retorno de carro tampoco sirve
    je .none
    cmp al, ' '      ;si hay un espacio todavia no sirve
    je .inc
    cmp al, 9    ;si es tab todavia no sirve
    je .inc
    ret   ;vuelve si no cayo en ninguno de esos casos porque entonces el caracter si era util

.inc:
    inc rdi       ;mover el puntero y seguir revisando
    jmp .skip

.none:
    xor eax, eax       ;no habia nada entonces pone eax=0 y se devuelve
    ret
