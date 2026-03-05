.286
.model tiny
.code
org 100h
locals @@


FRAME_FIRST_ELEM_OFFSET         EQU (80d*3+30d)*2
AX_VM_OFFSET                    EQU (80d*6+33d)*2
CF_VM_OFFSET                    EQU (80d*6+44d)*2

SCREEN_VM_SEGMENT               EQU 0b800h
SAVE_BUFFER_VM_SEGMENT          EQU 0be00h
DRAW_BUFFER_VM_SEGMENT          EQU 0bd00h

FRAME_ROW_WIDTH                 EQU 20d
NUM_OF_FRAME_ROWS               EQU 19d

SHADOW_LEFT_ELEM_OFFSET         EQU (80d*22+30d)*2
SHADOW_ATTRIBUTE                EQU 07h

WHITE_ON_CYAN_ATTRIBUTE         EQU 3Fh
REG_STRING_LEN                  EQU 7h
FLAG_STRING_LEN                 EQU 3h

Start:
                call replace09Int
                call replace08Int

                pushf
                push cs
                call registersDebugger09Int

                call endResidentProgram


endResidentProgram          proc

                            mov ax, 3100h
                            mov dx, offset endOfProgram
                            shr dx, 4
                            inc dx
                            int 21h

endResidentProgram          endp
;------------------------------------------------------------------------------------------------
;Ends resident program.
;Entry:
;Exit:
;Expected: The label "endOfProgram" is located at the end of the code.
;Destroyed: ax, dx
;------------------------------------------------------------------------------------------------

registersDebugger09Int      proc
                            push ax bx di es

                            in al, 60h
                            cmp al, 'W'
                            je @@modeON
                            cmp al, 'X'
                            je @@modeOFF

@@normalMode:               in al, 61h
                            or al, 80h
                            out 61h, al
                            and al, not 80h
                            out 61h, al

                            mov al, 20h
                            out 20h, al

                            pop es di bx ax

                            db 0eah
old09ofs                    dw 0
old09seg                    dw 0

@@modeON:                   cmp cs:printfRegsFlag, 0
                            jne @@normalMode
                            mov bx, FRAME_FIRST_ELEM_OFFSET
                            push SCREEN_VM_SEGMENT
                            pop ds
                            push SAVE_BUFFER_VM_SEGMENT
                            pop es
                            call copyFrame
                            mov ah, 0
                            call copyShadow

                            push SAVE_BUFFER_VM_SEGMENT
                            pop ds
                            push DRAW_BUFFER_VM_SEGMENT
                            pop es
                            mov ah, 1
                            call copyShadow


                            mov cs:printfRegsFlag, 1
                            call initChangingArrs
                            jmp @@normalMode

@@modeOFF:                  cmp cs:printfRegsFlag, 1h
                            jne @@normalMode

                            mov bx, FRAME_FIRST_ELEM_OFFSET

                            push SAVE_BUFFER_VM_SEGMENT
                            pop ds
                            push SCREEN_VM_SEGMENT
                            pop es
                            call copyFrame
                            mov ah, 0
                            call copyShadow

                            mov cs:printfRegsFlag, 0h
                            mov cs:saveRegsFlag, 0h
                            jmp @@normalMode

registersDebugger09Int      endp
;------------------------------------------------------------------------------------------------
;New 09 interrupt, which raises the printfRegsFlag to 1, when a key F11 is pressed.
;Entry:
;Exit:
;Expected:Old 09 interrupt was replaced to this function,
;old09ofs contains it's old segment and old09ofs contains it's old offset.
;Destroyed:
;------------------------------------------------------------------------------------------------


replace09Int                proc
                            mov ax, 3509h
                            int 21h

                            mov old09ofs, bx
                            mov bx, es
                            mov old09seg, bx

                            push 0
                            pop es

                            mov bx, 4*09h
                            cli
                            mov es:[bx], offset registersDebugger09Int
                            mov ax, cs
                            mov es:[bx+2], ax
                            sti

                            ret
replace09Int                endp
;------------------------------------------------------------------------------------------------
;Replaces interrupt 9 with a function registersDebugger09Int.
;Entry:
;Exit:
;Expected:
;Destroyed: ax, bx, es
;------------------------------------------------------------------------------------------------

replace08Int                proc

                            mov ax, 3508h
                            int 21h

                            mov old08ofs, bx
                            mov bx, es
                            mov old08seg, bx

                            push 0
                            pop es

                            mov bx, 4*08h
                            cli
                            mov es:[bx], offset printfRegs08Int
                            mov ax, cs
                            mov es:[bx+2], ax
                            sti

                            ret
replace08Int                endp
;------------------------------------------------------------------------------------------------
;Replaces interrupt 8 with a function printfRegs08Int.
;Entry:
;Exit:
;Expected:
;Destroyed: ax, bx, es
;------------------------------------------------------------------------------------------------


printfRegs08Int             proc
                            cmp cs:printfRegsFlag, 0h
                            jne @@continue
                            jmp @@end

@@continue:                 push ax bx cx dx si di bp ds es ss
                            mov bp, sp
                            cld

                            cmp cs:saveRegsFlag, 0h
                            jne @@alreadySaved
                            call saveRegsAndFlags
                            mov cs:saveRegsFlag, 1h

@@alreadySaved:             call updateSaveBuffer
                            call updateSaveShadow

                            push DRAW_BUFFER_VM_SEGMENT
                            pop es
                            mov bx, AX_VM_OFFSET

                            mov byte ptr es:[bx], 'a'
                            mov byte ptr es:[bx+2], 'x'
                            call printfHexRegValue

                            add bx, 80d*2
                            mov byte ptr es:[bx], 'b'
                            mov byte ptr es:[bx+2], 'x'
                            mov ax, [bp+16]
                            call printfHexRegValue

                            add bx, 80d*2
                            mov byte ptr es:[bx], 'c'
                            mov byte ptr es:[bx+2], 'x'
                            mov ax, [bp+14]
                            call printfHexRegValue

                            add bx, 80d*2
                            mov byte ptr es:[bx], 'd'
                            mov byte ptr es:[bx+2], 'x'
                            mov ax, [bp+12]
                            call printfHexRegValue

                            add bx, 80d*2
                            mov byte ptr es:[bx], 's'
                            mov byte ptr es:[bx+2], 'i'
                            mov ax, [bp+10]
                            call printfHexRegValue

                            add bx, 80d*2
                            mov byte ptr es:[bx], 'd'
                            mov byte ptr es:[bx+2], 'i'
                            mov ax, [bp+8]
                            call printfHexRegValue

                            add bx, 80d*2
                            mov byte ptr es:[bx], 'b'
                            mov byte ptr es:[bx+2], 'p'
                            mov ax, [bp+6]
                            call printfHexRegValue

                            add bx, 80d*2
                            mov byte ptr es:[bx], 's'
                            mov byte ptr es:[bx+2], 'p'
                            mov ax, sp
                            add ax, 13d*2
                            call printfHexRegValue

                            add bx, 80d*2
                            mov byte ptr es:[bx], 'd'
                            mov byte ptr es:[bx+2], 's'
                            mov ax, [bp+4]
                            call printfHexRegValue

                            add bx, 80d*2
                            mov byte ptr es:[bx], 'e'
                            mov byte ptr es:[bx+2], 's'
                            mov ax, [bp+2]
                            call printfHexRegValue

                            add bx, 80d*2
                            mov byte ptr es:[bx], 's'
                            mov byte ptr es:[bx+2], 's'
                            mov ax, [bp]
                            call printfHexRegValue

                            add bx, 80d*2
                            mov byte ptr es:[bx], 'c'
                            mov byte ptr es:[bx+2], 's'
                            mov ax, [bp+22]
                            call printfHexRegValue

                            add bx, 80d*2
                            mov byte ptr es:[bx], 'i'
                            mov byte ptr es:[bx+2], 'p'
                            mov ax, [bp+20]
                            call printfHexRegValue


                            mov ax, [bp+24]
                            sub bx, 80d*2*12d
                            add bx, 11d*2
                            call printfFlags

                            mov dh, 13d
                            mov dl, 14d
                            mov al, 30h

                            call printfRegistersFrame


                            push bx
                            call compareRegs
                            call compareFlags
                            pop bx


                            mov bx, FRAME_FIRST_ELEM_OFFSET
                            push DRAW_BUFFER_VM_SEGMENT
                            pop ds
                            push SCREEN_VM_SEGMENT
                            pop es
                            call copyFrame
                            mov ah, 0
                            call copyShadow

                            mov al, 20h
                            out 20h, al

                            pop ss es ds bp di si dx cx bx ax

@@end:                      db 0eah
old08ofs                    dw 0
old08seg                    dw 0

printfRegs08Int             endp
;------------------------------------------------------------------------------------------------
;New 08 interrupt, which prints the updated values ​​of the processor registers
;and flags in a frame at each tick of the system timer.
;Entry:
;Exit:
;Expected:Old 08 interrupt was replaced to this function,
;old08ofs contains it's old segment and old08ofs contains it's old offset.
;Destroyed:
;------------------------------------------------------------------------------------------------


printfHexRegValue           proc

                            xor dx, dx
                            mov dl, ah
                            shr dl, 4h

                            add dl, 30h
                            cmp dl, 39h
                            jbe @@notLetter1
                            add dl, 7h

@@notLetter1:               mov byte ptr es:[bx+6], dl

                            mov dl, ah
                            and dl, 00001111b
                            add dl, 30h
                            cmp dl, 39h
                            jbe @@notLetter2
                            add dl, 7h

@@notLetter2:               mov byte ptr es:[bx+8], dl

                            mov dl, al
                            shr dl, 4h

                            add dl, 30h
                            cmp dl, 39h
                            jbe @@notLetter3
                            add dl, 7h

@@notLetter3:               mov byte ptr es:[bx+10d], dl

                            mov dl, al
                            and dl, 00001111b
                            add dl, 30h
                            cmp dl, 39h
                            jbe @@notLetter4
                            add dl, 7h

@@notLetter4:               mov byte ptr es:[bx+12d], dl

                            ret
printfHexRegValue           endp
;------------------------------------------------------------------------------------------------
;Writes the hexadecimal value of the register to the video memory
;Entry: ax = current register value
;       bx = video memory offset of the beginning of the inscription reduced by 6 bytes
;       (the first 6 bytes are used to write the register name)
;Exit:
;Expected: es contains video memory segment
;Destroyed: dx
;------------------------------------------------------------------------------------------------

printfFlags             proc

                        mov di, bx
                        push ax bx
                        call printfFlagsColumn
                        pop bx ax

                        add bx, 4h

                        mov dx, ax
                        and dx, 0000000000000001b
                        cmp dx, 0
                        je @@zeroCF
                        mov byte ptr es:[bx], '1'
@@zeroCF:

                        mov dx, ax
                        and dx, 0000000001000000b
                        cmp dx, 0
                        je @@zeroZF
                        mov byte ptr es:[bx + 80d*2], '1'
@@zeroZF:
                        mov dx, ax
                        and dx, 0000000010000000b
                        cmp dx, 0
                        je @@zeroSF
                        mov byte ptr es:[bx + 80d*2*2], '1'
@@zeroSF:
                        mov dx, ax
                        and dx, 0000100000000000b
                        cmp dx, 0
                        je @@zeroOF
                        mov byte ptr es:[bx + 80d*2*3], '1'
@@zeroOF:
                        mov dx, ax
                        and dx, 0000000000000100b
                        cmp dx, 0
                        je @@zeroPF
                        mov byte ptr es:[bx + 80d*2*4], '1'
@@zeroPF:
                        mov dx, ax
                        and dx, 0000000000010000b
                        cmp dx, 0
                        je @@zeroAF
                        mov byte ptr es:[bx + 80d*2*5], '1'
@@zeroAF:
                        mov dx, ax
                        and dx, 0000001000000000b
                        cmp dx, 0
                        je @@zeroIF
                        mov byte ptr es:[bx + 80d*2*6], '1'
@@zeroIF:
                        mov dx, ax
                        and dx, 0000010000000000b
                        cmp dx, 0
                        je @@zeroDF
                        mov byte ptr es:[bx + 80d*2*7], '1'
@@zeroDF:
                        ret
printfFlags             endp
;------------------------------------------------------------------------------------------------
;Writes the value of the flags to the video memory
;Entry: ax = register of flags
;       bx = video memory offset of the CF
;Exit:
;Expected: es contains video memory segment.
;Destroyed: bx, cx, dx
;------------------------------------------------------------------------------------------------

printfFlagsColumn       proc

                        mov byte ptr es:[di], 'c'
                        mov byte ptr es:[di + 80d*2], 'z'
                        mov byte ptr es:[di + 80d*2*2], 's'
                        mov byte ptr es:[di + 80d*2*3], 'o'
                        mov byte ptr es:[di + 80d*2*4], 'p'
                        mov byte ptr es:[di + 80d*2*5], 'a'
                        mov byte ptr es:[di + 80d*2*6], 'i'
                        mov byte ptr es:[di + 80d*2*7], 'd'

                        add di, 2
                        mov al, '='
                        xor ah, ah
                        mov cx, 8h
                        push di
                        call printfVerticalString
                        mov al, 0
                        mov cx, 6h
                        call printfVerticalString
                        pop di


                        add di, 2
                        mov al, '0'
                        xor ah, ah
                        mov cx, 8h
                        call printfVerticalString

                        push di
                        mov al, 0
                        mov cx, 6h
                        call printfVerticalString
                        pop di

                        sub di, 4d
                        mov cx, 6h
                        call printfVerticalString

                        ret
printfFlagsColumn       endp
;----------------------------------------------------------------------------------------------
;Prints a column with processor flags with zeroed values.
;Entry: di = video memory offset.
;Exit:
;Expected: es contains the address of the video memory segment.
;Destroyed: ax, bx, cx, di
;----------------------------------------------------------------------------------------------

printfVerticalString    proc
                        mov bx, 80d*2
                        cmp ah, 0
                        je @@nextElem
                        neg bx

@@nextElem:             mov byte ptr es:[di], al
                        add di, bx
                        loop @@nextElem

                        ret

printfVerticalString     endp
;----------------------------------------------------------------------------------------------
;Prints vertical string
;Entry: al = symbol binary code
;       ah = direction flag (ah = 0, di += 80d*2; ah != 0, di -= 80d*2)
;       di = video memory offset
;       cx = length of string
;Exit:
;Expected: es contains the address of the video memory segment.
;Destroyed: cx, bx, di
;----------------------------------------------------------------------------------------------


printfFrameBackground           proc
                                push ax
                                call getFrameVideoMemoryOffset
                                pop ax

                                xor bx, bx
                                mov bl, dh
                                add bl, 6

printfFrameStr:                 xor cx, cx
                                mov cl, dl
                                add cl, 6

                                call printfFrameBackgroundString

                                add di, 160d

                                push ax
                                xor ax, ax
                                mov al, dl
                                cbw
                                shl ax, 1
                                sub di, ax
                                sub di, 12
                                pop ax

                                dec bl
                                cmp bl, 0
                                jne printfFrameStr

                                ret
printfFrameBackground           endp
;----------------------------------------------------------------------------------------------
;Prints frame centered frame background depending
;on the number of lines and their length in the message
;Entry: dh = the number of lines in the message
;       dl = max length of the string in the message
;       al = frame color binary code
;Exit:
;Expected:
;Destroyed: bx, di, cl
;----------------------------------------------------------------------------------------------


getFrameVideoMemoryOffset       proc

                                mov di, 25
                                mov al, dh
                                cbw
                                sub di, ax
                                shr di, 1
                                sub di, 3d
                                mov ax, 160
                                push dx
                                mul di
                                pop dx
                                mov di, ax

                                xor ax, ax
                                mov al, dl
                                cbw

                                mov bx, 80
                                sub bx, ax
                                sub bx, 6d
                                shr bx, 1
                                shl bx, 1
                                add di, bx

                                ret
getFrameVideoMemoryOffset       endp
;----------------------------------------------------------------------------------------------
;Gets a video memory offset for frame background depending
;on the number of lines and their length in the message
;Entry: dh = the number of lines in the message
;       dl = max length of the string in the message
;Exit:  di = video memory offset for frame background
;Expected:
;Destroyed: ax, bx, di
;----------------------------------------------------------------------------------------------


printfFrameBackgroundString         proc

@@printfByte:                       mov byte ptr es:[di+1], al
                                    add di, 2
                                    loop @@printfByte

                                    ret
printfFrameBackgroundString         endp
;----------------------------------------------------------------------------------------------
;Prints frameBackground string a certain of color
;Entry: di = starting address of the string
;       al = frame color binary code
;       cl = length of the string
;Exit:
;Expected: es contains the address of the video memory segment.
;Destroyed: di, cl
;----------------------------------------------------------------------------------------------

printfFrameForeground           proc

                                sub di, 80d*2*2
                                add di, 2

                                mov al, 0C8h
                                mov byte ptr es:[di], al

                                add di, 2

                                xor cx, cx
                                mov cl, dl
                                add cl, 2

                                mov al, 0CDh
                                push ax
                                mov ah, 0
                                call printHorizontalString
                                pop ax

                                mov al, 0BCh
                                mov byte ptr es:[di], al

                                mov al, dh
                                add al, 3
                                push ax
                                cbw
                                mov bx, 160d
                                push dx
                                mul bx
                                pop dx
                                sub di, ax
                                pop ax

                                mov al, 0BBh
                                mov byte ptr es:[di], al

                                sub di, 2

                                xor cx, cx
                                mov cl, dl
                                add cl, 2
                                mov al, 0CDh
                                push ax
                                mov ah, 1
                                call printHorizontalString
                                pop ax

                                mov al, 0C9h
                                mov byte ptr es:[di], al
                                add di, 80d*2

                                mov cl, dh
                                add cl, 2
                                mov al, 0BAh
                                push ax
                                mov ah, 0
                                call printfVerticalString
                                pop ax

                                sub di, 80d*2

                                push ax
                                mov al, dl
                                add al, 3
                                cbw
                                shl ax, 1
                                add di, ax
                                pop ax

                                mov cl, dh
                                add cl, 2
                                mov al, 0BAh
                                push ax
                                mov ah, 1
                                call printfVerticalString
                                pop ax

                                add di, 80d*2
                                mov al, 0h
                                call printfInternalFrame

                                add dh, 4h
                                add dl, 4h
                                sub di, (80d*2)
                                add di, 6h
                                call printfInternalFrame

                                ret
printfFrameForeground           endp
;----------------------------------------------------------------------------------------------
;Prints centered frame foreground depending
;on the number of lines and their length in the message
;Entry: dh = the number of lines in the message
;       dl = max length of the string in the message
;       di = video memory offset of the lower right corner of the frame
;Exit:
;Expected: es contains the address of the video memory segment.
;Destroyed: ax, bx, cx, si, di
;----------------------------------------------------------------------------------------------


printHorizontalString   proc
                        mov bx, 2
                        cmp ah, 0
                        je @@nextElem
                        neg bx

@@nextElem:             mov byte ptr es:[di], al
                        add di, bx
                        loop @@nextElem

                        ret

printHorizontalString   endp
;----------------------------------------------------------------------------------------------
;Prints horizontal string
;Entry: al = symbol binary code
;       ah = direction flag (a = 0, di += 2; a != 0, di -= 2)
;       di = video memory offset
;       cx = length of string
;Exit:
;Expected: es contains the address of the video memory segment.
;Destroyed: cx, bx
;----------------------------------------------------------------------------------------------

printfInternalFrame             proc

                                sub di, 2
                                mov cl, dl
                                add cl, 2
                                mov ah, 1
                                call printHorizontalString

                                add di, 2
                                mov cl, dh
                                add cl, 2
                                mov ah, 0
                                call printfVerticalString

                                sub di, 2*80d
                                mov cl, dl
                                add cl, 2
                                mov ah, 0
                                call printHorizontalString

                                sub di, 2
                                mov cl, dh
                                add cl, 2
                                mov ah, 1
                                call printfVerticalString

                                ret
printfInternalFrame             endp
;----------------------------------------------------------------------------------------------
;Prints centered internal frame foreground depending
;on the number of lines and their length in the message
;Entry: al = internal frame symbol ascii-code
;       dh = the number of lines in the message
;       dl = max length of the string in the message
;       di = video memory offset of the upper right corner of the frame
;Exit:
;Expected: es contains the address of the video memory segment.
;Destroyed: ax, cx, si, di
;----------------------------------------------------------------------------------------------

printfRegistersFrame    proc

                        call printfFrameBackground

                        call printfFrameForeground

                        mov di, (80d*4+42d)*2
                        mov byte ptr es:[di], 0CBh
                        add di, 80d*2
                        mov al, 0BAh
                        xor ah, ah
                        mov cx, 15d
                        call printfVerticalString
                        mov byte ptr es:[di], 0CAh

                        sub di, 162d
                        xor al, al
                        mov ah, 1
                        mov cx, 15d
                        call printfVerticalString

                        add di, 164d
                        xor ah, ah
                        mov cx, 15d
                        call printfVerticalString

                        mov di, (80d*5+40d)*2
                        mov cx, 15d
                        call printfVerticalString

                        mov di, (80d*5+35d)*2
                        mov cx, 15d
                        call printfVerticalString

                        ret
printfRegistersFrame    endp
;----------------------------------------------------------------------------------------------
;Prints centered frame for register debugger.
;on the number of lines and their length in the message
;Entry: al = internal frame symbol ascii-code
;       dh = the number of frame line
;       dl = max length of the string in line
;Exit:
;Expected: es contains the address of the video memory segment.
;Destroyed: ax, bx, cx, dx, si, di
;----------------------------------------------------------------------------------------------

copyFrame               proc

                        mov si, bx
                        mov di, bx
                        mov cx, NUM_OF_FRAME_ROWS

@@copyRow:
                        push cx si di
                        mov cx, FRAME_ROW_WIDTH
                        rep movsw
                        pop di si cx
                        add si, 160d
                        add di, 160d
                        loop @@copyRow

                        ret

copyFrame               endp
;----------------------------------------------------------------------------------------------
;Copies frame from src buffer to dest buffer.
;Entry: bx = video memory offset of the upper left
;            corner of the frame.
;       ds = video memory segment of the src buffer.
;       es = video memory segment of the dest buffer.
;Exit:
;Expected:
;Destroyed: ax, si, di, cx
;----------------------------------------------------------------------------------------------

updateSaveBuffer            proc
                            push ax
                            cld

                            mov ax, DRAW_BUFFER_VM_SEGMENT
                            mov es, ax
                            mov ax, SCREEN_VM_SEGMENT
                            mov ds, ax

                            mov si, FRAME_FIRST_ELEM_OFFSET
                            mov di, si

                            mov cx, NUM_OF_FRAME_ROWS
@@cmpRow:
                            push cx si di

                            mov cx, FRAME_ROW_WIDTH
@@cmpWord:
                            mov bx, ds:[si]
                            cmp bx, es:[di]
                            je  @@noChange

                            push es

                            mov ax, SAVE_BUFFER_VM_SEGMENT
                            mov es, ax
                            mov es:[si], bx

                            pop es
                            mov es:[di], bx

@@noChange:
                            add si, 2
                            add di, 2
                            loop @@cmpWord

                            pop di si cx
                            add si, 160d
                            add di, 160d
                            loop @@cmpRow

                            pop ax
                            ret
updateSaveBuffer            endp
;----------------------------------------------------------------------------------------------
;Compares DRAW buffer with frame on the screen
;and updates SAVE and DRAW buffers if it finds differences.
;Entry:
;Exit:
;Expected:
;Destroyed: si, di, es, ds, bx, cx
;----------------------------------------------------------------------------------------------

copyShadow          proc
                    cld

                    mov al, 0FFh
                    cmp ah, 0
                    je @@notDark
                    mov al, SHADOW_ATTRIBUTE
@@notDark:

                    mov si, SHADOW_LEFT_ELEM_OFFSET
                    mov di, si

                    mov cx, FRAME_ROW_WIDTH
@@shadowRow:
                    add si, 2
                    add di, 2
                    mov bx, ds:[si]
                    and bl, al
                    mov es:[di], bx
                    loop @@shadowRow


                    mov cx, (NUM_OF_FRAME_ROWS - 1)

@@shadowColumn:     sub si, 80d*2
                    sub di, 80d*2
                    mov bx, ds:[si]
                    and bh, al
                    mov es:[di], bx
                    loop @@shadowColumn

                    ret
copyShadow          endp
;----------------------------------------------------------------------------------------------
;Copies shadow from src buffer to dest buffer.
;Entry: ah = flag (if af == 0 just copies shadow, else make copy dark)
;       ds = video memory segment of the src buffer.
;       es = video memory segment of the dest buffer.
;Exit:
;Expected:
;Destroyed: al, si, di, cx, bx
;----------------------------------------------------------------------------------------------

updateSaveShadow            proc
                            push ax

                            mov ax, DRAW_BUFFER_VM_SEGMENT
                            mov es, ax
                            mov ax, SCREEN_VM_SEGMENT
                            mov ds, ax

                            mov si, SHADOW_LEFT_ELEM_OFFSET
                            mov di, si

                            mov cx, FRAME_ROW_WIDTH
@@cmpShadowRow:
                            add si, 2
                            add di, 2
                            mov bx, ds:[si]
                            cmp bx, es:[di]
                            je  @@noChangeInRow

                            push es

                            mov ax, SAVE_BUFFER_VM_SEGMENT
                            mov es, ax
                            mov es:[si], bx

                            pop es
                            and bh, SHADOW_ATTRIBUTE
                            mov es:[di], bx

@@noChangeInRow:
                            loop @@cmpShadowRow

                            mov cx, (NUM_OF_FRAME_ROWS - 1)
@@cmpShadowColumn:
                            sub si, 80d*2
                            sub di, 80d*2
                            mov bx, ds:[si]
                            cmp bx, es:[di]
                            je  @@noChangeInColumn

                            push es

                            mov ax, SAVE_BUFFER_VM_SEGMENT
                            mov es, ax
                            mov es:[si], bx

                            pop es
                            and bh, SHADOW_ATTRIBUTE
                            mov es:[di], bx

@@noChangeInColumn:
                            loop @@cmpShadowColumn

                            pop ax
                            ret
updateSaveShadow            endp
;----------------------------------------------------------------------------------------------
;Compares shadow of the frame in
;DRAW buffer with those on the screen
;and updates SAVE and DRAW buffer if it finds differences.
;Entry:
;Exit:
;Expected:
;Destroyed: si, di, es, ds, bx, cx
;----------------------------------------------------------------------------------------------

saveRegsAndFlags            proc
                            push ax dx

                            mov cs:[regsArr], ax

                            mov ax, [bp + 16d]
                            mov cs:[regsArr + 2d], ax

                            mov ax, [bp + 14d]
                            mov cs:[regsArr + 4d], ax

                            mov ax, [bp + 12d]
                            mov cs:[regsArr + 6d], ax

                            mov ax, [bp + 10d]
                            mov cs:[regsArr + 8d], ax

                            mov ax, [bp + 8d]
                            mov cs:[regsArr + 10d], ax

                            mov ax, [bp + 6d]
                            mov cs:[regsArr + 12d], ax

                            mov ax, sp
                            add ax, 16d*2
                            mov cs:[regsArr + 14d], ax

                            mov ax, [bp + 4d]
                            mov cs:[regsArr + 16d], ax

                            mov ax, [bp + 2d]
                            mov cs:[regsArr + 18d], ax

                            mov ax, [bp]
                            mov cs:[regsArr + 20d], ax

                            mov ax, [bp + 22d]
                            mov cs:[regsArr + 22d], ax

                            mov ax, [bp + 20d]
                            mov cs:[regsArr + 24d], ax

                            mov ax, [bp + 24d]

                            mov dx, ax
                            and dx, 0000000000000001b
                            cmp dx, 0
                            je @@zeroCF
                            mov byte ptr cs:[flagsArr], 1
@@zeroCF:

                            mov dx, ax
                            and dx, 0000000001000000b
                            cmp dx, 0
                            je @@zeroZF
                            mov byte ptr cs:[flagsArr + 1], 1
@@zeroZF:
                            mov dx, ax
                            and dx, 0000000010000000b
                            cmp dx, 0
                            je @@zeroSF
                            mov byte ptr cs:[flagsArr + 2], 1
@@zeroSF:
                            mov dx, ax
                            and dx, 0000100000000000b
                            cmp dx, 0
                            je @@zeroOF
                            mov byte ptr cs:[flagsArr + 3], 1
@@zeroOF:
                            mov dx, ax
                            and dx, 0000000000000100b
                            cmp dx, 0
                            je @@zeroPF
                            mov byte ptr cs:[flagsArr + 4], 1
@@zeroPF:
                            mov dx, ax
                            and dx, 0000000000010000b
                            cmp dx, 0
                            je @@zeroAF
                            mov byte ptr cs:[flagsArr + 5], 1
@@zeroAF:
                            mov dx, ax
                            and dx, 0000001000000000b
                            cmp dx, 0
                            je @@zeroIF
                            mov byte ptr cs:[flagsArr + 6], 1
@@zeroIF:
                            mov dx, ax
                            and dx, 0000010000000000b
                            cmp dx, 0
                            je @@zeroDF
                            mov byte ptr cs:[flagsArr + 7], 1

@@zeroDF:
                            pop dx ax
                            ret
saveRegsAndFlags            endp
;----------------------------------------------------------------------------------------------
;Saves registers and flags values in buffers.
;Entry:
;Exit:
;Expected:                  [bp]    = ss
;                           [bp+2]  = es
;                           [bp+4]  = ds
;                           [bp+6]  = bp
;                           [bp+8]  = di
;                           [bp+10] = si
;                           [bp+12] = dx
;                           [bp+14] = cx
;                           [bp+16] = bx
;                           [bp+18] = ax
;                           [bp+20] = ip
;                           [bp+22] = cs
;                           [bp+24] = flags
;Destroyed:
;----------------------------------------------------------------------------------------------

compareRegs                 proc
                            mov bx, AX_VM_OFFSET

                            cmp cs:[regChanged], 1h
                            je @@whiteAX
                            mov ax, [bp + 18d]
                            cmp ax, cs:[regsArr]
                            je @@noChangeAX
                            mov cs:[regChanged], 1h

@@whiteAX:                  mov cx, REG_STRING_LEN
                            call makeTextWhite
@@noChangeAX:
                            add bx, 80d*2

                            cmp cs:[regChanged + 1], 1h
                            je @@whiteBX
                            mov ax, [bp + 16d]
                            cmp ax, cs:[regsArr + 1*2]
                            je @@noChangeBX
                            mov cs:[regChanged + 1], 1h

@@whiteBX:                  mov cx, REG_STRING_LEN
                            call makeTextWhite
@@noChangeBX:
                            add bx, 80d*2

                            cmp cs:[regChanged + 2], 1h
                            je @@whiteCX
                            mov ax, [bp + 14d]
                            cmp ax, cs:[regsArr + 2*2]
                            je @@noChangeCX
                            mov cs:[regChanged + 2], 1h

@@whiteCX:                  mov cx, REG_STRING_LEN
                            call makeTextWhite
@@noChangeCX:
                            add bx, 80d*2

                            cmp cs:[regChanged + 3], 1h
                            je @@whiteDX
                            mov ax, [bp + 12d]
                            cmp ax, cs:[regsArr + 3*2]
                            je @@noChangeDX
                            mov cs:[regChanged + 3], 1h

@@whiteDX:                  mov cx, REG_STRING_LEN
                            call makeTextWhite
@@noChangeDX:
                            add bx, 80d*2

                            cmp cs:[regChanged + 4], 1h
                            je @@whiteSI
                            mov ax, [bp + 10d]
                            cmp ax, cs:[regsArr + 4*2]
                            je @@noChangeSI
                            mov cs:[regChanged + 4], 1h

@@whiteSI:                  mov cx, REG_STRING_LEN
                            call makeTextWhite
@@noChangeSI:
                            add bx, 80d*2

                            cmp cs:[regChanged + 5], 1h
                            je @@whiteDI
                            mov ax, [bp + 8d]
                            cmp ax, cs:[regsArr + 5*2]
                            je @@noChangeDI
                            mov cs:[regChanged + 5], 1h

@@whiteDI:                  mov cx, REG_STRING_LEN
                            call makeTextWhite
@@noChangeDI:
                            add bx, 80d*2

                            cmp cs:[regChanged + 6], 1h
                            je @@whiteBP
                            mov ax, [bp + 6d]
                            cmp ax, cs:[regsArr + 6*2]
                            je @@noChangeBP
                            mov cs:[regChanged + 6], 1h

@@whiteBP:                  mov cx, REG_STRING_LEN
                            call makeTextWhite
@@noChangeBP:
                            add bx, 80d*2

                            cmp cs:[regChanged + 7], 1h
                            je @@whiteSP
                            mov ax, bp
                            add ax, 26d
                            cmp ax, cs:[regsArr + 7*2]
                            je @@noChangeSP
                            mov cs:[regChanged + 7], 1h

@@whiteSP:                  mov cx, REG_STRING_LEN
                            call makeTextWhite
@@noChangeSP:
                            add bx, 80d*2

                            cmp cs:[regChanged + 8], 1h
                            je @@whiteDS
                            mov ax, [bp + 4d]
                            cmp ax, cs:[regsArr + 8*2]
                            je @@noChangeDS
                            mov cs:[regChanged + 8], 1h

@@whiteDS:                  mov cx, REG_STRING_LEN
                            call makeTextWhite
@@noChangeDS:
                            add bx, 80d*2

                            cmp cs:[regChanged + 9], 1h
                            je @@whiteES
                            mov ax, [bp + 2d]
                            cmp ax, cs:[regsArr + 9d*2]
                            je @@noChangeES
                            mov cs:[regChanged + 9d], 1h

@@whiteES:                  mov cx, REG_STRING_LEN
                            call makeTextWhite
@@noChangeES:
                            add bx, 80d*2

                            cmp cs:[regChanged + 10], 1h
                            je @@whiteSS
                            mov ax, [bp]
                            cmp ax, cs:[regsArr + 10d*2]
                            je @@noChangeSS
                            mov cs:[regChanged + 10d], 1h

@@whiteSS:                  mov cx, REG_STRING_LEN
                            call makeTextWhite
@@noChangeSS:
                            add bx, 80d*2

                            cmp cs:[regChanged + 11], 1h
                            je @@whiteCS
                            mov ax, [bp + 22d]
                            cmp ax, cs:[regsArr + 11d*2]
                            je @@noChangeCS
                            mov cs:[regChanged + 11d], 1h

@@whiteCS:                  mov cx, REG_STRING_LEN
                            call makeTextWhite
@@noChangeCS:
                            add bx, 80d*2

                            cmp cs:[regChanged + 12], 1h
                            je @@whiteIP
                            mov ax, [bp + 20d]
                            cmp ax, cs:[regsArr + 12d*2]
                            je @@noChangeIP
                            mov cs:[regChanged + 12d], 1h

@@whiteIP:                  mov cx, REG_STRING_LEN
                            call makeTextWhite
@@noChangeIP:
                            ret
compareRegs                 endp
;----------------------------------------------------------------------------------------------
;Compares current registers values with values saved in buffer
;and changes the color of characters in the register line to white color
;if it finds differences.
;Entry: bx = video memory offset of the start of register string
;Exit:
;Expected: array regsArr contains saved flag values.
;Destroyed: cx
;----------------------------------------------------------------------------------------------

compareFlags                proc
                            mov ax, [bp + 24d]
                            mov bx, CF_VM_OFFSET


                            cmp cs:[flagsChanged], 1h
                            je @@whiteCF
                            mov dx, ax
                            and dx, 0000000000000001b
                            cmp cs:[flagsArr], dl
                            je @@noChangeCF
                            mov cs:[flagsChanged], 1h
@@whiteCF:
                            mov cx, FLAG_STRING_LEN
                            call makeTextWhite
@@noChangeCF:
                            add bx, 80d*2


                            cmp cs:[flagsChanged + 1], 1h
                            je @@whiteZF
                            mov dx, ax
                            and dx, 0000000001000000b
                            shr dx, 6d
                            cmp cs:[flagsArr + 1], dl
                            je @@noChangeZF
                            mov cs:[flagsChanged + 1], 1h
@@whiteZF:
                            mov cx, FLAG_STRING_LEN
                            call makeTextWhite
@@noChangeZF:
                            add bx, 80d*2


                            cmp cs:[flagsChanged + 2], 1h
                            je @@whiteSF
                            mov dx, ax
                            and dx, 0000000010000000b
                            shr dx, 7d
                            cmp cs:[flagsArr + 2], dl
                            je @@noChangeSF
                            mov cs:[flagsChanged + 2], 1h
@@whiteSF:
                            mov cx, FLAG_STRING_LEN
                            call makeTextWhite
@@noChangeSF:
                            add bx, 80d*2

                            cmp cs:[flagsChanged + 3], 1h
                            je @@whiteOF
                            mov dx, ax
                            and dx, 0000100000000000b
                            shr dx, 11d
                            cmp cs:[flagsArr + 3], dl
                            je @@noChangeOF
                            mov cs:[flagsChanged + 3], 1h
@@whiteOF:
                            mov cx, FLAG_STRING_LEN
                            call makeTextWhite
@@noChangeOF:
                            add bx, 80d*2


                            cmp cs:[flagsChanged + 4], 1h
                            je @@whitePF
                            mov dx, ax
                            and dx, 0000000000000100b
                            shr dx, 2d
                            cmp cs:[flagsArr + 4], dl
                            je @@noChangePF
                            mov cs:[flagsChanged + 4], 1h
@@whitePF:
                            mov cx, FLAG_STRING_LEN
                            call makeTextWhite
@@noChangePF:
                            add bx, 80d*2


                            cmp cs:[flagsChanged + 5], 1h
                            je @@whiteAF
                            mov dx, ax
                            and dx, 0000000000010000b
                            shr dx, 4d
                            cmp cs:[flagsArr + 5], dl
                            je @@noChangeAF
                            mov cs:[flagsChanged + 5], 1h
@@whiteAF:
                            mov cx, FLAG_STRING_LEN
                            call makeTextWhite
@@noChangeAF:
                            add bx, 80d*2


                            cmp cs:[flagsChanged + 6], 1h
                            je @@whiteIF
                            mov dx, ax
                            and dx, 0000001000000000b
                            shr dx, 9d
                            cmp cs:[flagsArr + 6], dl
                            je @@noChangeIF
                            mov cs:[flagsChanged + 6], 1h
@@whiteIF:
                            mov cx, FLAG_STRING_LEN
                            call makeTextWhite
@@noChangeIF:
                            add bx, 80d*2


                            cmp cs:[flagsChanged + 7], 1h
                            je @@whiteDF
                            mov dx, ax
                            and dx, 0000010000000000b
                            shr dx, 10d
                            cmp cs:[flagsArr + 7], dl
                            je @@noChangeDF
                            mov cs:[flagsChanged + 7], 1h
@@whiteDF:
                            mov cx, FLAG_STRING_LEN
                            call makeTextWhite
@@noChangeDF:
                            ret
compareFlags                endp
;----------------------------------------------------------------------------------------------
;Compares current flags values with values saved in buffer
;and changes the color of characters in the register line to white color
;if it finds differences.
;Entry: bx = video memory offset of the start of register string
;Exit:
;Expected: array flagsArr contains saved flag values.
;Destroyed: cx
;----------------------------------------------------------------------------------------------

makeTextWhite               proc
                            push bx


@@regString:                mov byte ptr es:[bx + 1], WHITE_ON_CYAN_ATTRIBUTE
                            add bx, 2d
                            loop @@regString

                            pop bx
                            ret
makeTextWhite               endp
;----------------------------------------------------------------------------------------------
;Changes the color of characters in the line to white color.
;Entry: bx = video memory offset of the start of the string
;       cx = length of the string
;Exit:
;Expected:
;Destroyed: cx
;----------------------------------------------------------------------------------------------

initChangingArrs            proc
                            xor al, al
                            xor di, di

                            mov cx, 13d

@@continue1:                mov byte ptr cs:[regChanged + di], al
                            inc di
                            loop @@continue1

                            mov cx, 8d
                            xor di, di
@@continue2:                mov byte ptr cs:[flagsChanged + di], al
                            inc di
                            loop @@continue2

                            ret
initChangingArrs            endp
;----------------------------------------------------------------------------------------------
;Inits arrays "regChanged" and "flagsChanged" with zeroes.
;Entry:
;Exit:
;Expected:
;Destroyed: al, di, cx
;----------------------------------------------------------------------------------------------

printfRegsFlag              db  0
saveRegsFlag                db  0
regsArr                     dw  13 dup(0)
regChanged                  db  13 dup(0)

flagsArr                    db  8 dup(0)
flagsChanged                db  8 dup(0)

endOfProgram:
end                         Start
