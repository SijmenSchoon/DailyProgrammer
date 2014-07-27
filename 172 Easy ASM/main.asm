; Written by Vijfhoek in 2014
; Released to the public domain
; Do with this whatever you want
format PE console
entry Start
stack 0x100

include 'win32a.inc'

section '.text' code executable
Start:
	; Allocate memory for the filename
	invoke malloc, 256
	mov [p_filename], eax
	; Ask for the filename
	invoke printf, c_filename
	invoke gets, [p_filename]

	; Allocate memory for the string to print
	invoke malloc, 256
	mov [p_text], eax
	; Ask for the string to print
	invoke printf, c_text
	invoke gets, [p_text]

	; Allocate memory for the buffer
	invoke malloc, 32
	mov [p_buffer], eax

	invoke printf, c_confirm, [p_text], [p_filename]

	; Count the characters
	mov esi, [p_text]
	xor ecx, ecx
@@:
	lodsb
	or al, al
	jz @f

	inc ecx
	jmp @b
@@:
	mov [count], ecx
	; Print the amount of characters found
	invoke printf, c_characters, ecx

	; Print the image dimensions
	mov ecx, [count]
	shl ecx, 3
	mov [width], ecx
	invoke printf, c_dimensions, ecx

	; Open the file
	invoke CreateFile, [p_filename], GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	mov [filehandle], eax

	; If the result + 1 == 0 (result == -1), print the error
	or eax, eax
	jns @f
	invoke GetLastError
	invoke printf, c_err_createfile, eax

	jmp Exit
@@:

	; Write the header
	invoke sprintf, [p_buffer], c_header_fmt, [width]
	invoke WriteFile, [filehandle], [p_buffer], eax, 0, 0

	; Write the characters
	mov ebx, c_font
	mov ecx, 8
CharLoop:
	mov esi, [p_text]
	xor eax, eax
CharRowLoop:
	; Load an ASCII code from the string
	lodsb
	; Exit the loop when character == '\0'
	or al, al
	jz CharRowLoopExit
	; Multiply the character by 8, because every char sprite is 8 bytes
	shl eax, 3
	; Add the font location to get the location of the character
	add eax, ebx
	; Write the byte to file
	push ecx
		invoke WriteFile, [filehandle], eax, 1, 0, 0
	pop ecx
	; Continue
	jmp CharRowLoop
CharRowLoopExit:
	; If all 8 rows have been printed, exit
	dec ecx
	jz CharLoopExit
	; Else, increase the font location to go to the next row and continue
	inc ebx
	jmp CharLoop
CharLoopExit:
	; Close the file
	invoke CloseHandle, [filehandle]

Exit:
	invoke ExitProcess
	ret

section '.rdata' data readable
	c_filename   db "Output file: ", 0x00
	c_text	     db "Text to output: ", 0x00
	c_confirm    db "Outputting '%s' to %s", 0x0A, 0x00
	c_characters db "Amount of characters: %d", 0x0A, 0x00
	c_dimensions db "Image dimensions: %dx8", 0x0A, 0x00
	c_string_fmt db "%s", 0x00
	c_header_fmt db "P4 %d 8 ", 0x00

	c_err_createfile db "Couldn't create file: %d!", 0x0A, 0x00

	; Include the font
	include 'font.inc'

section '.data' data readable writable
	p_filename dd 0x00
	p_text	   dd 0x00
	p_buffer   dd 0x00
	count	   dd 0x00
	width	   dd 0x00
	filehandle dd 0x00

section '.idata' data readable import
	library msvcrt,   'msvcrt.dll', \
		kernel32, 'kernel32.dll'
	import msvcrt, printf,	'printf', \
		       sprintf, 'sprintf', \
		       scanf,	'scanf', \
		       malloc,	'malloc', \
		       getchar, 'getchar'`, \
		       gets,	'gets'

	import kernel32, ExitProcess,  'ExitProcess', \
			 CreateFile,   'CreateFileA', \
			 WriteFile,    'WriteFile', \
			 CloseHandle,  'CloseHandle', \
			 GetLastError, 'GetLastError'