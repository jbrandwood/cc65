;
; Ullrich von Bassewitz, 16.11.2002
;
; int write (int fd, const void* buf, unsigned count);
;

        .export         _write
        .constructor    initstdout

        .import         rwcommon
        .import         __errno, __oserror
        .importzp       sp, ptr1, ptr2, ptr3

        .include        "errno.inc"
        .include        "fcntl.inc"
        .include        "cbm.inc"
        .include        "filedes.inc"


;--------------------------------------------------------------------------
; initstdout: Open the stdout and stderr file descriptors for the screen.

.proc   initstdout

        lda     #LFN_WRITE
        sta     fdtab+STDOUT_FILENO
        sta     fdtab+STDERR_FILENO
        lda     #CBMDEV_SCREEN
        sta     unittab+STDOUT_FILENO
        sta     unittab+STDERR_FILENO
        lda     #STDOUT_FILENO + LFN_OFFS
        jsr     @L1
        lda     #STDERR_FILENO + LFN_OFFS
@L1:    ldx     #CBMDEV_SCREEN
        ldy     #$FF
        jsr     SETLFS
        jmp     OPEN            ; Will always succeed

.endproc

;--------------------------------------------------------------------------
; _write


.proc   _write

        jsr     rwcommon        ; Pop params, check handle
        bcs     invalidfd       ; Branch if handle not ok

; Check if the LFN is valid and the file is open for writing

        adc     #LFN_OFFS       ; Carry is already clear
        tax
        lda     fdtab-LFN_OFFS,x; Get flags for this handle
        and     #LFN_WRITE      ; File open for writing?
        beq     notopen

; Valid lfn. Make it the output file

        jsr     CKOUT
        bcs     error
        bcc     @L2

; Output the next character from the buffer

@L0:    ldy     #0
        lda     (ptr2),y
        inc     ptr2
        bne     @L1
        inc     ptr2+1          ; A = *buf++;
@L1:    jsr     BSOUT
        bcs     error           ; Bail out on errors

; Count characters written

        inc     ptr3
        bne     @L2
        inc     ptr3+1

; Decrement count

@L2:    inc     ptr1
        bne     @L0
        inc     ptr1+1
        bne     @L0

; Wrote all chars, close the output channel

        jsr     CLRCH

; Return the number of chars written

        lda     ptr3
        ldx     ptr3+1
        rts

; Error entry, file descriptor is invalid

invalidfd:
        lda     #EINVAL
        sta     __errno
        lda     #0
        sta     __errno+1
        beq     errout

; Error entry, file is not open

notopen:
        lda     #3              ; File not open
        bne     error

; Error entry, status not ok

error5: lda     #5              ; Device not present
error:  sta     __oserror
errout: lda     #$FF
        tax                     ; Return -1
        rts

.endproc




