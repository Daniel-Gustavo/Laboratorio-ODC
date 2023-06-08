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
	mov x21, #170    // coordenada x inicial auto
	mov x22, #50	 // coordenada y inicial auto

redraw:
	mov x0, x20
	mov x26, #0
	mov x2, SCREEN_HEIGH         // Y Size

loop1:
	mov x1, SCREEN_WIDTH         // X Size

///////////////////////////llamar funciones///////////////////////////
cycle_check: 
    //cielo
	bl color_dia
    
	//sol_luna
	mov x3, #65                 // Radio del circulo
	mul x4, x3, x3	 
	mov x5, #640		        // Coordenada X (centro del circulo)
	mov x6, #130			    // Coordenada Y
	bl sol_luna

	//piso
	cmp x2, x19					// Se fija si la coordenada y se encuentra en el cuarto inferior de la pantalla
	b.le color_piso
	fin_piso:

	//calle
	mov x5, #525				// posicion x donde empieza el grosor
	mov x6, xzr				    // posicion y donde se basa el grosor
	mov x3, #410			    // grosor de calle a la altura x6
	bl calle

	//rueda derecha
	add x5, x21, #20 			// coordenada x de la parte derecha de la rueda
	sub x6, x22, #40			// coordenada y de la parte inferior de la rueda
	mov x3, #50					// longitud de la rueda
	mov x4, #50					// altura de la rueda
	bl rueda

	//rueda izquierda
	add x5, x21, #230			// igual que rueda derecha
	sub x6, x22, #40
	mov x3, #50
	mov x4, #50
	bl rueda
		
//---------------------auto---------------------------------------------  
	// parte de arriba
	add x5, x21, #300		   // coordenada x (esquina izquierda)
	add x6, x22, #115		   // coordenada y (esquina inferior)
	mov x3, #300               // longitud de la base
	mov x4, #120			   // altura del parelolgramo
	mov x7, #12			   	   // grosor
	bl paralelogramo           // imprime un rectangulo con los datos dados
	
	// parte de abajo
	mov x5, x21	     	       // coordenada x (esquina derecha)
	mov x6, x22			       // coordenada y (esquina inferior)
	mov x3, #300               // longitud rectangulo
	mov x4, #120			   // altura rectangulo
	bl rectangulo
	
	// parrilla ----(multiples rectangulos vacios juntos)---------
	add x5, x21, #81		   // coordenada x (esquina izquierda)
	add x6, x22, #25		   // coordenada y (esquina inferior)
	mov x3, #8			       // ancho de division
	mov x4, #50				   // alto de divison
	mov x7, #2	               // grosor de parrilla (hacia adentro)
	mov x8, #14				   // cantidad de iteraciones
	iteracion:
	bl rectangulo_vacio
	add x5, x5, #10			   // espacio entre esquinas derechas de los rectangulos vacios
	sub x8, x8, #1
	cbnz x8, iteracion


	//luz derecha
	mov x3, #25                 // Radio del circulo
	mul x4, x3, x3	 
	add x5, x21, #45 		    // Coordenada X (centro del circulo)
	add x6, x22, #50 		    // Coordenada Y
	bl luz                      // imprime un circulo con los datos dados

	//luz izquierda
	mov x3, #25                 // Radio del circulo
	mul x4, x3, x3	 
	add x5, x21, #255		    // Coordenada X (centro del circulo)
	add x6, x22, #50		    // Coordenada Y
	bl luz                      // imprime un circulo con los datos dados

///////////////////////////ciclo///////////////////////////	
	cycle:
	stur w10,[x0]       // Colorear el pixel N
	add x0,x0,4         // Siguiente pixel
	sub x1,x1,1         // Decrementar contador X
	cbnz x1,cycle_check // Si no terminó la fila, salto
	sub x2,x2,1         // Decrementar contador Y
	cbnz x2,loop1       // Si no es la última fila, salto

///////////////////////////detector de teclas///////////////////////////
	repeat:
	mov x9, GPIO_BASE
	// Atención: se utilizan registros w porque la documentación de broadcom
	// indica que los registros que estamos leyendo y escribiendo son de 32 bits
	
	// Setea gpios 0 - 9 como lectura
	str wzr, [x9, GPIO_GPFSEL0]

	// Lee el estado de los GPIO 0 - 31
	ldr w15, [x9, GPIO_GPLEV0]

	// And bit a bit mantiene el resultado del bit 2 en w10 (notar 0b... es binario)
	// al inmediato se lo refiere como "máscara" en este caso:
	// - Al hacer AND revela el estado del bit 2
	// - Al hacer OR "setea" el bit 2 en 1
	// - Al hacer AND con el complemento "limpia" el bit 2 (setea el bit 2 en 0)
	and w11, w15, 0b00000010

	// si w11 es 0 entonces el GPIO 1 estaba liberado
	// de lo contrario será distinto de 0, (en este caso particular 2)
	// significando que el GPIO 1 fue presionado
	// llamar auto
	cbnz w11, tecla_w
	b end
	tecla_w:
	cbz x27, on
	mov x27, #0
	b end
	on:
	mov x27, #1
	end:
	cbz w11, skip
	b redraw
	skip:
	b repeat

///////////////////////////objetos///////////////////////////

	tiempo:                
		cbz x27, color_sol
		cbnz x27, color_luna
		ret
	
	sol_luna:                
		sub x9, x5, x1
		sub x11, x6, x2
		mul x9, x9, x9
		mul x11, x11, x11
		add x9, x9, x11
		cmp x4, x9
		b.ge tiempo
		ret

	calle:
		sub x9, x5, x1
		sub x11, x6, x2 
		lsl x9, x9, #2
		add x11, x11, x9
		cmp x11, xzr
		b.lt end_calle
		sub x9, x5, x1
		sub x9, x9, x3
		sub x11, x6, x2 
		lsl x9, x9, #2
		sub x11, x11, x9
		cmp x11, xzr
		b.lt end_calle
		cmp x2, x19
		b.le color_luna
		end_calle:
		ret

	luz:                      
		sub x9, x5, x1
		sub x11, x6, x2
		mul x9, x9, x9
		mul x11, x11, x11
		add x9, x9, x11
		cmp x4, x9
		b.ge borde
		ret

	borde:
		sub x3, x3, #5               // Radio del circulo
		mul x4, x3, x3	
		sub x9, x5, x1
		sub x11, x6, x2
		mul x9, x9, x9
		mul x11, x11, x11
		add x9, x9, x11
		cmp x4, x9
		b.ge color_foco
		b.le color_borde

	rectangulo: 
		sub x9, x5, x1
		sub x11, x6, x2
		cmp x9, xzr
		b.gt end_rectangulo
		cmp x11, xzr
		b.gt end_rectangulo
		add x12, x5, x3
		add x13, x6, x4
		sub x9, x12, x1
		sub x11, x13, x2
		cmp x9, xzr
		b.lt end_rectangulo
		cmp x11, xzr
		b.lt end_rectangulo
		b.ge color_auto_abajo
		end_rectangulo:
		ret

	paralelogramo:
		cmp x2, x6
		b.le end_paralelogramo_vacio
		add x9, x6, x4
		cmp x2, x9
		b.ge end_paralelogramo_vacio
		sub x9, x5, x1
		sub x11, x6, x2 
		lsl x9, x9, #3
		add x11, x11, x9
		cmp x11, xzr
		b.lt end_paralelogramo_vacio
		sub x9, x5, x1
		sub x9, x9, #300
		sub x11, x6, x2 
		lsl x9, x9, #3
		sub x11, x11, x9
		cmp x11, xzr
		b.lt end_paralelogramo_vacio	

		add x9, x6, x7
		cmp x2, x9
		b.le color_auto_arriba
		add x9, x6, x4
		sub x9, x9, x7
		cmp x2, x9
		b.gt color_auto_arriba
		sub x9, x5, x1
		sub x11, x6, x2 
		sub x9, x9, x7
		lsl x9, x9, #3
		add x11, x11, x9
		cmp x11, xzr
		b.le color_auto_arriba
		sub x9, x5, x1
		sub x9, x9, #300
		sub x11, x6, x2 
		add x9, x9, x7
		lsl x9, x9, #3
		sub x11, x11, x9
		cmp x11, xzr
		b.le color_auto_arriba	
		b.gt color_vidrio
		end_paralelogramo_vacio:
		ret

	rectangulo_vacio:
		sub x9, x5, x1
		sub x11, x6, x2
		cmp x9, xzr
		b.ge end_rectangulo_vacio
		cmp x11, xzr
		b.ge end_rectangulo_vacio
		add x12, x5, x3
		add x13, x6, x4
		sub x9, x11, x2
		sub x9, x12, x1
		sub x11, x13, x2
		cmp x9, xzr
		b.le end_rectangulo_vacio
		cmp x11, xzr
		b.le end_rectangulo_vacio

		sub x9, x5, x1
		sub x11, x6, x2
		add x9, x9, x7
		add x11, x11, x7
		cmp x9, xzr
		b.ge color_luna
		cmp x11, xzr
		b.ge color_luna
		add x12, x5, x3
		add x13, x6, x4
		sub x12, x12, x7
		sub x13, x13, x7
		sub x9, x11, x2
		sub x9, x12, x1
		sub x11, x13, x2
		cmp x9, xzr
		b.le color_luna
		cmp x11, xzr
		b.le color_luna
		end_rectangulo_vacio:
		ret

	rueda: 
		sub x9, x5, x1
		sub x11, x6, x2
		cmp x9, xzr
		b.ge end_rueda
		cmp x11, xzr
		b.ge end_rueda
		add x5, x5, x3
		add x6, x6, x4
		sub x9, x11, x2
		sub x9, x5, x1
		sub x11, x6, x2
		cmp x9, xzr
		b.le end_rueda
		cmp x11, xzr
		b.le end_rueda
		b.ge color_rueda
		end_rueda:
		ret

///////////////////////////colores///////////////////////////

	color_foco:
		cbnz x27, luz_prendida
		movz x10, 0x00A2, lsl 16
		movk x10, 0xABB1, lsl 00     // w10 = luz_apagada--color gris (0xA2ABB1)
		ret

	luz_prendida:
		movz x10, 0x00FB, lsl 16
		movk x10, 0xC117, lsl 00     // w10 = luz_prendida -- amarillo (0xFBC117)
			ret
	blue:
		mov x10, #0xff
		ret

	color_noche:                     
		movz x10, 0x0000, lsl 16
		movk x10, 0x0000, lsl 00     // w10 = fondo--color celeste (0x008fff)
		mov x9, #480
		sub x9, x9, x2
		add x10, x10, x9
		cmp x10, #0xff
		b.gt blue
		ret

	celeste:	#2001D7
		mov x10, x12
		ret

	color_dia: #1F85D7 #2001D7
		cmp x27, xzr
		b.ne color_noche
		movz x10, 0x001F, lsl 16
		movk x10, 0x85d7, lsl 00
		movz x12, 0x0020, lsl 16
		movk x12, 0x01d7, lsl 00
		mov x9, #480
		sub x9, x9, x2
		lsl x9, x9, #8
		add x10, x10, x9
		cmp x10, x12
		b.le celeste
		ret

	color_piso:		
		movz x10, 0xFF00, lsl 16
		movk x10, 0x9230, lsl 00     // w10 = fondo--color celeste (0x008fff)
		mov x9, x2
		lsr x9, x9, #2
		add x10, x10, x9
		b fin_piso

	color_sol:                 
		movz x10, 0x00FB, lsl 16
		movk x10, 0xC117, lsl 00     // w10 = -color amarillo (0xFBC117)
		ret
	color_luna:
		movz x10, 0x00A2, lsl 16
		movk x10, 0xABB1, lsl 00     // w10 = -color gris (0xA2ABB1)
		ret

	color_rueda: 
		movz x10, 0x001F, lsl 16
		movk x10, 0x1F1F, lsl 00     // w10 = color negro y rayas grices (0x1F1F1F)
		add x26, x26, #1
		cmp x26, #40
		b.ge gris
		end_gris:
		ret
		gris:
			mov x26, #0
			movz x10, 0x004F, lsl 16
			movk x10, 0x4F4F, lsl 00     // w10 = color gris (0x4F4F4F)
			b end_gris
			
	color_borde:
		movz x10, 0x0010, lsl 16
		movk x10, 0x1314, lsl 00     // w10 = circulo--color amarillo (0x101314)
		ret

	color_auto_arriba:
		movz x10, 0x00DF, lsl 16
		movk x10, 0x564A, lsl 00     // w10 = color de arriba (0xDF564A)
		ret
	color_auto_abajo:
		movz x10, 0x00DF, lsl 16
		movk x10, 0x362A, lsl 00     // w10 = color de abajo (0xDF362A)
		cmp x11, #15
		b.le color_auto_arriba
		sub x9, x4, x11
		lsr x9, x9, #1
		add x10, x10, x9
		lsl x9, x9, #8
		add x10, x10, x9
		ret
	color_vidrio:
		movz x10, 0x001F, lsl 16
		movk x10, 0x1F1F, lsl 00     // w10 = color negro (0x1F1F1F)
		sub x9, x2, x6
		lsr x9, x9, #1
		add x10, x10, x9
		ret
	
	//---------------------------------------------------------------
	// Infinite Loop
InfLoop:

	b InfLoop
