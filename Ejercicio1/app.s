	.equ SCREEN_WIDTH,   640
	.equ SCREEN_HEIGH,   480
	.equ BITS_PER_PIXEL, 32

	.equ GPIO_BASE,    0x3f200000
	.equ GPIO_GPFSEL0, 0x00
	.equ GPIO_GPLEV0,  0x34
	.globl main

main:
	mov x20, x0
	mov x19, SCREEN_HEIGH
	lsr x19, x19, #2
	mov x27, #0

///////////////////////////coordenadas iniciales///////////////////////////
	mov x17, #200     // coordenada inicial x del sol
	mov x18, #680     // coordenada inicial x de la luna
	mov x21, #180     // coordenada x inicial auto
	mov x22, #50	  // coordenada y inicial auto
	mov x23, x21

repeat:
	mov x0, x20
	mov x2, SCREEN_HEIGH         // Y Size
loop1:
	mov x1, SCREEN_WIDTH         // X Size

///////////////////////////llamar objetos///////////////////////////
cycle_check: 
	//cielo
	capa_1:                      // mientras menor  la capa mas al fondo se encuentra
	bl color_fondo

//----------------SOL------------------
	capa_2:
	mov x3, #70                 // Radio del circulo
	mul x4, x3, x3	 
	mov x5, x17				     // Coordenada X (centro del circulo)
	mov x6, #340			     // Coordenada Y
	bl sol

	capa_3:
//-------------piso-----------------------------
	cmp x2, x19
	b.le color_piso

	capa_4:
//---------------- ruedas--------------------
	//rueda derecha
	add x5, x21, #20 
	sub x6, x22, #40
	mov x3, #70
	mov x4, #50
	bl ruedas

	//rueda izquierda
	add x5, x21, #210
	sub x6, x22, #40
	mov x3, #70
	mov x4, #50
	bl ruedas

//------------parte baja del auto------------------
	mov x5, x21	     	       // coordenada x (esquina derecha)
	mov x6, x22			       // coordenada y (esqueina inferior)
	mov x3, #300               // rectangle Length
	mov x4, #120			   // rectangle Height
	bl cuadrado                // imprime un cuadrado con los datos dados

//------------parte alta del auto--------------------
//contorno rojo del vidrio
	mov x5, x21	     	       // coordenada x (esquina derecha)
	mov x6, x22			       // coordenada y (esqueina inferior)
	mov x3, #260               // rectangle Length
	mov x4, #80			       // rectangle Height
	add x5, x21, #20
	add x6, x22, #118
	bl cuadrado                // imprime un cuadrado con los datos dados

// vidrio parte alta del auto
	mov x5, x21	     	       // coordenada x (esquina derecha)
	mov x6, x22			       // coordenada y (esqueina inferior)
	mov x3, #240               // rectangle Length
	mov x4, #75			       // rectangle Height
	add x5, x21, #30
	add x6, x22, #118
	bl frente_auto             // imprime un cuadrado con los datos dados

//-------------luces del auto----------------------------
// llamar luz derecha
	mov x3, #25               // Radio del circulo
	mul x4, x3, x3	 
	add x5, x21, #45 		  // Coordenada X (centro del circulo)
	add x6, x22, #70 		  // Coordenada Y
	bl contornoluz            // imprime un circulo con los datos dados

// llamar luz izquierda
	mov x3, #25               // Radio del circulo
	mul x4, x3, x3	 
	add x5, x21, #255		  // Coordenada X (centro del circulo)
	add x6, x22, #70		  // Coordenada Y
	bl contornoluz            // imprime un circulo con los datos dados

///////////////////////////ciclo///////////////////////////	
	cycle:
	stur w10,[x0]       // Colorear el pixel N
	add x0,x0,4         // Siguiente pixel
	sub x1,x1,1         // Decrementar contador X
	cbnz x1,cycle_check // Si no terminó la fila, salto
	sub x2,x2,1         // Decrementar contador Y
	cbnz x2,loop1       // Si no es la última fila, salto

///////////////////////////detector de teclas///////////////////////////
	mov x9, GPIO_BASE
	str wzr, [x9, GPIO_GPFSEL0]
	ldr w15, [x9, GPIO_GPLEV0]
	and w11, w15, 0x4
	cmp w11, #4
	b.eq tecla_d
	and w11, w15, 0x10
	cmp w11, #0x10
	b.eq tecla_a
	and w11, w15, 0x20
	cmp w11, #0x20
	b.eq tecla_espacio
	B end

	tecla_a:
	sub x21, x21, #4
	b end
	tecla_d:
	add x21, x21, #4
	b end
	tecla_espacio:
	cmp x27, #0
	b.eq on
	mov x27, #0
	b end
	on:
		mov x27, #1
	end:

///////////////////////////movimiento///////////////////////////
	cmp x17, #1300
	b.lt repeat
	b repeat
	cbz x2, done
	
///////////////////////////objetos///////////////////////////
	sol:                
		sub x9, x5, x1
		sub x11, x6, x2
		mul x9, x9, x9
		mul x11, x11, x11
		add x9, x9, x11
		cmp x4, x9
		b.ge color_sol
		ret
	
//-----------LUCES-------------------
	contornoluz:                      
		sub x9, x5, x1
		sub x11, x6, x2
		mul x9, x9, x9
		mul x11, x11, x11
		add x9, x9, x11
		cmp x4, x9
		b.ge luz
		ret

	luz:
		sub x3, x3, #5 // Radio del circulo
		mul x4, x3, x3	
		sub x9, x5, x1
		sub x11, x6, x2
		mul x9, x9, x9
		mul x11, x11, x11
		add x9, x9, x11
		cmp x4, x9
		b.ge color_vidrio
		b.le color_negro

	cuadrado: 
		sub x9, x5, x1
		sub x11, x6, x2
		cmp x9, xzr
		b.ge end_cuadrado
		cmp x11, xzr
		b.ge end_cuadrado
		add x5, x5, x3
		add x6, x6, x4
		sub x9, x11, x2
		sub x9, x5, x1
		sub x11, x6, x2
		cmp x9, xzr
		b.le end_cuadrado
		cmp x11, xzr
		b.le end_cuadrado
		b.ge color_auto
		end_cuadrado:
		ret

	ruedas: 
		sub x9, x5, x1
		sub x11, x6, x2
		cmp x9, xzr
		b.ge end_ruedas
		cmp x11, xzr
		b.ge end_ruedas
		add x5, x5, x3
		add x6, x6, x4
		sub x9, x11, x2
		sub x9, x5, x1
		sub x11, x6, x2
		cmp x9, xzr
		b.le end_ruedas
		cmp x11, xzr
		b.le end_ruedas
		b.ge color_negro
		end_ruedas:
		ret

	frente_auto: 
		sub x9, x5, x1
		sub x11, x6, x2
		cmp x9, xzr
		b.ge end_frente_auto
		cmp x11, xzr
		b.ge end_frente_auto
		add x5, x5, x3
		add x6, x6, x4
		sub x9, x11, x2
		sub x9, x5, x1
		sub x11, x6, x2
		cmp x9, xzr
		b.le end_frente_auto
		cmp x11, xzr
		b.le end_frente_auto
		b.ge color_negro
		end_frente_auto:
		ret

///////////////////////////colores///////////////////////////
	color_vidrio:
		cmp x27, #1
		b.eq color_sol
		movz x10, 0x0070, lsl 16
		movk x10, 0x748F, lsl 00     // w10 = -color gris mas oscuro (0x70748F)
		ret

	blue:
		mov x10, #0xff
		ret

	color_fondo:
		movz x10, 0x0000, lsl 16
		movk x10, 0x0000, lsl 00   
		mov x9, #480
		sub x9, x9, x2
		add x10, x10, x9
		cmp x10, #0xff
		b.GT blue
		ret

	color_piso:                    
		movz x10, 0x0000, lsl 16
		movk x10, 0xE600, lsl 00    // w10 = -color verde (0x00E600)
		b capa_4

	color_sol:                  
		movz x10, 0x00FB, lsl 16
		movk x10, 0xC117, lsl 00    // w10 = -color amarillo(0xFBC117)
		ret

	color_negro: 
		movz x10, 0x001F, lsl 16
		movk x10, 0x1F1F, lsl 00     // w10 = -color negro (0x1F1F1F)
		ret

	color_auto:
		movz x10, 0x00a0, lsl 16
		movk x10, 0x0000, lsl 00     // w10 = -color rojo (0xa00000)
		ret

done: InfLoop: b InfLoop
