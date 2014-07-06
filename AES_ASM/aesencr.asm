dane segment
  
  state db 16 dup(?)
  
  key db 02bh, 028h, 0abh, 009h
      db 07eh, 0aeh, 0f7h, 0cfh
      db 015h, 0d2h, 015h, 04fh
      db 016h, 0a6h, 088h, 03ch
      db 160 dup(?)
  
  sBox db 063h, 07Ch, 077h, 07Bh, 0F2h, 06Bh, 06Fh, 0C5h, 030h, 001h, 067h, 02Bh, 0FEh, 0D7h, 0ABh, 076h
       db 0CAh, 082h, 0C9h, 07Dh, 0FAh, 059h, 047h, 0F0h, 0ADh, 0D4h, 0A2h, 0AFh, 09Ch, 0A4h, 072h, 0C0h
       db 0B7h, 0FDh, 093h, 026h, 036h, 03Fh, 0F7h, 0CCh, 034h, 0A5h, 0E5h, 0F1h, 071h, 0D8h, 031h, 015h
       db 004h, 0C7h, 023h, 0C3h, 018h, 096h, 005h, 09Ah, 007h, 012h, 080h, 0E2h, 0EBh, 027h, 0B2h, 075h
       db 009h, 083h, 02Ch, 01Ah, 01Bh, 06Eh, 05Ah, 0A0h, 052h, 03Bh, 0D6h, 0B3h, 029h, 0E3h, 02Fh, 084h
       db 053h, 0D1h, 000h, 0EDh, 020h, 0FCh, 0B1h, 05Bh, 06Ah, 0CBh, 0BEh, 039h, 04Ah, 04Ch, 058h, 0CFh
       db 0D0h, 0EFh, 0AAh, 0FBh, 043h, 04Dh, 033h, 085h, 045h, 0F9h, 002h, 07Fh, 050h, 03Ch, 09Fh, 0A8h
       db 051h, 0A3h, 040h, 08Fh, 092h, 09Dh, 038h, 0F5h, 0BCh, 0B6h, 0DAh, 021h, 010h, 0FFh, 0F3h, 0D2h
       db 0CDh, 00Ch, 013h, 0ECh, 05Fh, 097h, 044h, 017h, 0C4h, 0A7h, 07Eh, 03Dh, 064h, 05Dh, 019h, 073h
       db 060h, 081h, 04Fh, 0DCh, 022h, 02Ah, 090h, 088h, 046h, 0EEh, 0B8h, 014h, 0DEh, 05Eh, 00Bh, 0DBh
       db 0E0h, 032h, 03Ah, 00Ah, 049h, 006h, 024h, 05Ch, 0C2h, 0D3h, 0ACh, 062h, 091h, 095h, 0E4h, 079h
       db 0E7h, 0C8h, 037h, 06Dh, 08Dh, 0D5h, 04Eh, 0A9h, 06Ch, 056h, 0F4h, 0EAh, 065h, 07Ah, 0AEh, 008h
       db 0BAh, 078h, 025h, 02Eh, 01Ch, 0A6h, 0B4h, 0C6h, 0E8h, 0DDh, 074h, 01Fh, 04Bh, 0BDh, 08Bh, 08Ah
       db 070h, 03Eh, 0B5h, 066h, 048h, 003h, 0F6h, 00Eh, 061h, 035h, 057h, 0B9h, 086h, 0C1h, 01Dh, 09Eh
       db 0E1h, 0F8h, 098h, 011h, 069h, 0D9h, 08Eh, 094h, 09Bh, 01Eh, 087h, 0E9h, 0CEh, 055h, 028h, 0DFh
       db 08Ch, 0A1h, 089h, 00Dh, 0BFh, 0E6h, 042h, 068h, 041h, 099h, 02Dh, 00Fh, 0B0h, 054h, 0BBh, 016h
  
  Rcon db 1h, 2h, 4h, 8h, 10h, 20h, 40h, 80h, 1bh, 36h
  
  MC_Matrix db 2, 3, 1, 1
            db 1, 2, 3, 1
            db 1, 1, 2, 3
            db 3, 1, 1, 2
  
  _offset dw ?
  
;   newline db 13,10,"$"
  
  decrypted db "plik.txt",0
  encrypted db "plik.enc",0
  
  error db "blad; byc moze nie ma pliku o nazwie plik.txt/plik.enc?",13,10,"$"

dane ends

stos segment stack
dw 128 dup(?)
stos ends

assume cs: kod

kod segment
start:
  mov ax, dane
  mov ds, ax
  
  call KeySchedule
  
  mov al, 0 ;read
  mov dx, offset decrypted
  mov ah, 3dh
  int 21h
  jnc decFileOpened
    call raiseError
  decFileOpened:
  mov bx, ax
  ;bx - file handle
  
  
  mov cx, 0
  mov dx, offset encrypted
  mov ah, 3ch
  int 21h
  jnc fileCreated
    call raiseError
  fileCreated:
  
  mov al, 1 ;write
  mov dx, offset encrypted
  mov ah, 3dh
  int 21h
  jnc encFileOpened
    call raiseError
  encFileOpened:
  ;ax - file handle
  
  push ax
    readLoop:
      mov ah, 3fh
      mov cx, 16
      mov dx, offset state
      int 21h
      jnc successfulRead
        call raiseError
      successfulRead:
      
      cmp ax, 16
      jl readLoop_end
      
      call AESencrypt
      
      pop ax
        xor ax, bx ; swap ax, bx
        xor bx, ax
        xor ax, bx
        
        mov cx, 16
        mov dx, offset state
        
        push ax
          mov ah, 40h
          int 21h
        pop ax
        
        jnc successfulWrite
          call raiseError
        successfulWrite:
        
        xor ax, bx ; swap ax, bx
        xor bx, ax
        xor ax, bx
      push ax
      
;       push bx
;         mov bx, offset state
;         call print
;       pop bx
      
      jmp readLoop
    readLoop_end:
    
    push bx
      mov bx, offset state
      add bx, ax
      mov cl, al
      zeroFillLoop:
        mov byte ptr ds:[bx], 0
        
        inc bx
        inc ax
        cmp ax, 15
        jl zeroFillLoop
      
      mov byte ptr ds:[bx], cl
    pop bx
    
    call AESencrypt
    
    pop ax
      xor ax, bx ; swap ax, bx
      xor bx, ax
      xor ax, bx
      
      mov cx, 16
      mov dx, offset state
      
      push ax
        mov ah, 40h
        int 21h
      pop ax
      
      jnc successfulWrite2
        call raiseError
      successfulWrite2:
      
      xor ax, bx ; swap ax, bx
      xor bx, ax
      xor ax, bx
    push ax
    
;     push bx
;       mov bx, offset state
;       call print
;     pop bx
    
  pop ax
  
  
  ;zamkniecie plikow
  push ax
  mov ah, 3eh
  int 21h
  pop bx
  mov ah, 3eh
  int 21h
  
  jmp Exit
  
;;;;;

raiseError:
  mov dx, offset error
  mov ah, 09h
  int 21h
  jmp Exit
  ret

; printAlByte:
;   push bx
;   push cx
;   push dx
;   
;   xor ah, ah
;   
;   mov dl, 16
;   div dl
;   mov dl, al
;   call dlHexToChr
;   
;   push ax
;   
;   mov ah, 02h
;   int 21h
;   
;   pop ax
;   
;   mov dl, ah
;   call dlHexToChr
;   
;   mov ah, 02h
;   int 21h
;   
;   mov dx, offset newline
;   mov ah, 09h
;   int 21h
;   
;   pop dx
;   pop cx
;   pop bx
;   ret
; 
; printByte:
;   push ax
;   push cx
;   push dx
;   
;   mov al, ds:[bx]
;   
;   xor ah, ah
;   
;   mov dl, 16
;   div dl
;   mov dl, al
;   call dlHexToChr
;   
;   push ax
;   
;   mov ah, 02h
;   int 21h
;   
;   pop ax
;   
;   mov dl, ah
;   call dlHexToChr
;   
;   mov ah, 02h
;   int 21h
;   
;   mov dx, offset newline
;   mov ah, 09h
;   int 21h
;   
;   pop dx
;   pop cx
;   pop ax
;   ret
; 
; print:
;   push ax
;   push cx
;   push dx
;   
;   mov cx, 4
;   printOuterLoop:
;     push cx
;     mov cx, 4
;     printLoop:
;       mov al, ds:[bx]
;       
;       xor ah, ah
;       
;       mov dl, 16
;       div dl
;       mov dl, al
;       call dlHexToChr
;       
;       push ax
;       
;       mov ah, 02h
;       int 21h
;       
;       pop ax
;       
;       mov dl, ah
;       call dlHexToChr
;       
;       mov ah, 02h
;       int 21h
;       
;       mov dl, 32
;       int 21h
;       
;       inc bx
;       dec cx
;       
;       jnz printLoop
;         mov dx, offset newline
;         mov ah, 09h
;         int 21h
;         pop cx
;         dec cx
;         jnz printOuterLoop
;     int 21h
;   
;   pop dx
;   pop cx
;   pop ax
;   ret
; 
; dlHexToChr:
;   add dl, 48
;   cmp dl, 57
;   jle dlHexToChr_end
;     add dl, 39
;   dlHexToChr_end:
;   ret
; 
; pause:
;   push ax
;   mov ah, 08h
;   int 21h
;   pop ax
;   ret

AESencrypt:
  push ax
  push bx
  push cx
  push dx
  
  mov cx, 0 ;iteracja razy 16
  call AddRoundKey
  add cx, 16
  AESencrypt_loop:
    call SubBytes
    call ShiftRows
    call MixColumns
    call AddRoundKey
    
    add cx, 16
    cmp cx, 160
    jl AESencrypt_loop
  call SubBytes
  call ShiftRows
  call AddRoundKey
  
  pop dx
  pop cx
  pop bx
  pop ax
  ret

KeySchedule:
  push ax
  push bx
  push cx
  push dx
  
  mov cx, 0 ;it
  mov word ptr ds:[_offset], 16
  
  KeySchedule_loop:
    
    mov bx, word ptr ds:[_offset]
    mov bl, byte ptr ds:[key+bx-9]
    xor bh, bh
    mov bl, byte ptr ds:[sBox+bx]
    mov dl, bl
    mov bx, word ptr ds:[_offset]
    xor dl, byte ptr ds:[key+bx-16]
    mov bx, cx
    xor dl, byte ptr ds:[Rcon+bx]
    mov bx, word ptr ds:[_offset]
    mov byte ptr ds:[key+bx], dl
    
    mov bx, word ptr ds:[_offset]
    mov bl, byte ptr ds:[key+bx-5]
    xor bh, bh
    mov bl, byte ptr ds:[sBox+bx]
    mov dl, bl
    mov bx, word ptr ds:[_offset]
    xor dl, byte ptr ds:[key+bx-12]
    mov bx, word ptr ds:[_offset]
    mov byte ptr ds:[key+bx+4], dl
    
    mov bx, word ptr ds:[_offset]
    mov bl, byte ptr ds:[key+bx-1]
    xor bh, bh
    mov bl, byte ptr ds:[sBox+bx]
    mov dl, bl
    mov bx, word ptr ds:[_offset]
    xor dl, byte ptr ds:[key+bx-8]
    mov bx, word ptr ds:[_offset]
    mov byte ptr ds:[key+bx+8], dl
    
    mov bx, word ptr ds:[_offset]
    mov bl, byte ptr ds:[key+bx-13]
    xor bh, bh
    mov bl, byte ptr ds:[sBox+bx]
    mov dl, bl
    mov bx, word ptr ds:[_offset]
    xor dl, byte ptr ds:[key+bx-4]
    mov bx, word ptr ds:[_offset]
    mov byte ptr ds:[key+bx+12], dl
    
    push cx
    mov cx, 0
    KeySchedule_innerLoop:
      mov bx, word ptr ds:[_offset]
      add bx, cx
      
      mov dl, byte ptr ds:[key+bx]
      xor dl, byte ptr ds:[key+bx-15]
      mov byte ptr ds:[key+bx+1], dl
      
      mov dl, byte ptr ds:[key+bx+1]
      xor dl, byte ptr ds:[key+bx-14]
      mov byte ptr ds:[key+bx+2], dl
      
      mov dl, byte ptr ds:[key+bx+2]
      xor dl, byte ptr ds:[key+bx-13]
      mov byte ptr ds:[key+bx+3], dl
      
      add cx, 4
      cmp cx, 16
      jl KeySchedule_innerLoop
    pop cx
    
    add word ptr ds:[_offset], 16
    
    inc cx
    cmp cx, 10
    jge KeySchedule_loop_end
    jmp KeySchedule_loop
    KeySchedule_loop_end:
  
  pop dx
  pop cx
  pop bx
  pop ax
  ret

AddRoundKey:
  mov bx, 0
  AddRoundKey_loop:
    add bx, cx
    mov dl, ds:[key+bx]
    sub bx, cx
    xor byte ptr ds:[state+bx], dl
    
    inc bx
    cmp bx, 16
    jl AddRoundKey_loop
  ret

SubBytes:
  mov bx, 0
  SubBytes_loop:
    mov dl, ds:[state+bx]
    push bx
    mov bl, dl
    xor bh, bh
    mov dl, ds:[sBox+bx]
    pop bx
    mov ds:[state+bx], dl
    
    inc bx
    cmp bx, 16
    jl SubBytes_loop
  ret

ShiftRows:
  mov al, ds:[state+4]
  mov ah, ds:[state+5]
  mov bl, ds:[state+6]
  mov bh, ds:[state+7]
  mov ds:[state+4], ah
  mov ds:[state+5], bl
  mov ds:[state+6], bh
  mov ds:[state+7], al
  
  mov al, ds:[state+8 ]
  mov ah, ds:[state+10]
  mov ds:[state+8 ], ah
  mov ds:[state+10], al
  mov al, ds:[state+9 ]
  mov ah, ds:[state+11]
  mov ds:[state+9 ], ah
  mov ds:[state+11], al
  
  mov al, ds:[state+12]
  mov ah, ds:[state+13]
  mov bl, ds:[state+14]
  mov bh, ds:[state+15]
  mov ds:[state+12], bh
  mov ds:[state+13], al
  mov ds:[state+14], ah
  mov ds:[state+15], bl
  
  ret

; al *= ah w GF(2**8)
mult:
  push cx
  push bx
  
  mov bl, 0
  mov cx, 8
  mult_loop:
    mov bh, ah
    and bh, 1
    jz mult_if_end
      xor bl, al
    mult_if_end:
    mov bh, al
    shl al, 1
    and bh, 80h
    jz mult_if2_end
      xor al, 1Bh
    mult_if2_end:
    shr ah, 1
    
    dec cx
    jnz mult_loop
  
  mov al, bl
  
  pop bx
  pop cx
  ret

;wejscie: bx jako offset
multiplyColumn:
  push cx
  
  
  mov al, ds:[state+bx]
  mov ah, ds:[MC_Matrix]
  call mult
  mov dl, al
  
  mov al, ds:[state+bx+4]
  mov ah, ds:[MC_Matrix+1]
  call mult
  xor dl, al
  
  mov al, ds:[state+bx+8]
  mov ah, ds:[MC_Matrix+2]
  call mult
  xor dl, al
  
  mov al, ds:[state+bx+12]
  mov ah, ds:[MC_Matrix+3]
  call mult
  xor dl, al
  
  
  mov al, ds:[state+bx]
  mov ah, ds:[MC_Matrix+4]
  call mult
  mov dh, al
  
  mov al, ds:[state+bx+4]
  mov ah, ds:[MC_Matrix+5]
  call mult
  xor dh, al
  
  mov al, ds:[state+bx+8]
  mov ah, ds:[MC_Matrix+6]
  call mult
  xor dh, al
  
  mov al, ds:[state+bx+12]
  mov ah, ds:[MC_Matrix+7]
  call mult
  xor dh, al
  
  
  mov al, ds:[state+bx]
  mov ah, ds:[MC_Matrix+8]
  call mult
  mov cl, al
  
  mov al, ds:[state+bx+4]
  mov ah, ds:[MC_Matrix+9]
  call mult
  xor cl, al
  
  mov al, ds:[state+bx+8]
  mov ah, ds:[MC_Matrix+10]
  call mult
  xor cl, al
  
  mov al, ds:[state+bx+12]
  mov ah, ds:[MC_Matrix+11]
  call mult
  xor cl, al
  
  
  mov al, ds:[state+bx]
  mov ah, ds:[MC_Matrix+12]
  call mult
  mov ch, al
  
  mov al, ds:[state+bx+4]
  mov ah, ds:[MC_Matrix+13]
  call mult
  xor ch, al
  
  mov al, ds:[state+bx+8]
  mov ah, ds:[MC_Matrix+14]
  call mult
  xor ch, al
  
  mov al, ds:[state+bx+12]
  mov ah, ds:[MC_Matrix+15]
  call mult
  xor ch, al
  
  
  mov ds:[state+bx   ], dl
  mov ds:[state+bx+4 ], dh
  mov ds:[state+bx+8 ], cl
  mov ds:[state+bx+12], ch
  
  pop cx
  ret

MixColumns:
  mov bx, 0
  MixColumns_loop:
    call multiplyColumn
    
    inc bx
    cmp bx, 4
    jl MixColumns_loop
  
  ret

Exit:
  mov ax, 4C00h
  int 21h

kod ends
end start