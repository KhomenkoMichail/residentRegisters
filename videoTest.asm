.model tiny
.code
org 100h

Start:

    push 0
    pop ds

    push 0b800h
    pop es

    mov si, 0h
    mov di, 0h

    mov cx, 0FFFFh

next:    mov al, ds:[si]
         xor al, cl
         mov es:[di], al
         inc si
         inc di
         loop next

next2:  in al, 60h
        cmp al, 1
        jne next2

    ret
end Start
