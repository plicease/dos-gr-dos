; GR-DOS smoke test program (decision 14). Built with Open Watcom wasm and
; wlink, independently of the DOS source tree.
;
; Prints "GRDOS-HELLO DOS x.yy" with the version INT 21h function 30h
; reports, then exits with errorlevel 7 for the batch file to test.

        .8086
        .model  tiny
        .code
        org     100h

start:
        mov     ah, 30h                 ; get DOS version: AL major, AH minor
        int     21h
        add     al, '0'
        mov     major, al
        mov     al, ah
        aam                             ; AH = tens, AL = units
        add     ax, '00'
        mov     minor, ah
        mov     minor + 1, al

        mov     dx, offset msg
        mov     ah, 09h
        int     21h

        mov     ax, 4C07h
        int     21h

msg     db      'GRDOS-HELLO DOS '
major   db      '?', '.'
minor   db      '??', 13, 10, '$'

        end     start
