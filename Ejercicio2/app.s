// uso de registros desde x0 hasta x27
// x0 acceso a pixeles
// x1 coordenada x de pixel
// x2 coordenada y de pixel
// x3-x8 argumentos de funciones, no modificar dentro de funciones
// x9 temporal, es modificado dentro de funciones y puede ser usado afuera
// x10 color de pixel, no debe ser modificado salvo por funciones en parte "color"
// x11-x13 temporales, son modificados dentro de funciones y pueden ser usados afuera
// x14-x18 no usados

// no sobreescribir en lo siguiente 
// x19 toggle entre los colores del auto (0 -> rojo, 1 -> amarillo, 2 -> verde, 3 -> azul)
// x20 posicion base del framebuffer
// x21 coordenada x inicial auto
// x22 coordenada y inicial auto
// x23 coordenada x inicial sol/luna (en relacion a la coordenada x 320)
// x24 coordenada y inicial sol/luna (en relacion a la coordenada y 120)
// x25 toggle entre dia y noche (0 -> dia, 1 -> noche)
// x26 le da efecto a las ruedas
// x27 toggle entre luz apagada y prendida, (0 -> off, 1 -> on)

// durante este programa, se refieren a coordenadas x e y, la coordenada X=0 es la izquierda de la pantalla, mientras que la coordenada X=640 es la derecha
// tener en cuenta ya que esto puede ser confuso al pensar como se grafican diagonales (por ejemplo, y=x resulta en una diagonal que baja de derecha a izquierda)


	
	.equ SCREEN_WIDTH,   640
	.equ SCREEN_HEIGH,   480
	.equ BITS_PER_PIXEL, 32

	.equ GPIO_BASE,    0x3f200000
	.equ GPIO_GPFSEL0, 0x00
	.equ GPIO_GPLEV0,  0x34


	.globl main

main:
	// x0 contiene la direccion base del framebuffer
	mov x20, x0 // Guarda la dirección base del framebuffer en x20
	//---------------- CODE HERE ------------------------------------
	mov x27, xzr
	mov x25, xzr
	mov x19, xzr

///////////////////////////coordenadas iniciales///////////////////////////
	mov x21, #170    // coordenada x inicial auto
	mov x22, #50	 // coordenada y inicial auto
	mov x23, #385    // coordenadas iniciales  (en relacion al centro de la pantalla) del sol_luna
	mov x24, xzr

redraw:
	mov x0, x20	

	mov x2, SCREEN_HEIGH         // Y Size
loop1:
	mov x1, SCREEN_WIDTH         // X Size

///////////////////////////llamar funciones///////////////////////////

cycle_check: 
	                  // mientras menor  la capa mas al fondo se encuentra
	//cielo
	cmp x2, #120
	b.le skip_cielo				// no dibuja ni cielo no sol/luna si y<120
	bl color_dia
	
                                // cosas entre piso y cielo
	//sol_luna
	mov x3, #65                 // Radio del circulo
	mul x4, x3, x3
	mov x5, #320
	mov x6, #120
	add x5, x5, x23		        // Coordenada X (centro del circulo)
	add x6, x6, x24			    // Coordenada Y
	
	bl sol_luna

	skip_cielo:

	cmp x2, #120					
	b.gt skip_piso				// no pinta piso ni calle si y>120
	//piso
	bl color_pasto				


	cmp x1, #80
	b.lt skip_auto_calle
	cmp x1, #560
	b.gt skip_auto_calle		// no intenta pintar calle ni auto si x<80 o x>560

	//calle
	mov x5, #525				// posicion x donde empieza el grosor
	mov x6, xzr				    // posicion y donde se basa el grosor
	mov x3, #410			    // grosor de calle a la altura x6
	bl calle

	skip_piso:

	cmp x1, #80
	b.lt skip_auto_calle
	cmp x1, #560
	b.gt skip_auto_calle
	cmp x2, #290
	b.gt skip_auto_calle		// no intenta pintar auto si x<80 o x>560 o y>290
	
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
	
	
	// auto  
	// parte de arriba
	add x5, x21, #300		   // coordenada x (esquina izquierda)
	add x6, x22, #115		   // coordenada y (esquina inferior)
	mov x3, #300               // longitud de la base
	mov x4, #120			   // altura del parelolgramo
	mov x7, #12			   	   // grosor
	bl paralelogramo_vacio          // imprime un rectangulo con los datos dados
	// parte de abajo
	mov x5, x21	     	       // coordenada x (esquina derecha)
	mov x6, x22			       // coordenada y (esquina inferior)
	mov x3, #300               // longitud rectangulo
	mov x4, #120			   // altura rectangulo
	bl rectangulo
	// parrilla (multiples rectangulos vacios juntos)
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

	skip_auto_calle:
	///////////////////////////ciclo///////////////////////////
	
	cycle:
	stur w10,[x0]       // Colorear el pixel N
	add x0,x0,4         // Siguiente pixel
	sub x1,x1,1         // Decrementar contador X
	cbnz x1,cycle_check // Si no terminó la fila, salto
	sub x2,x2,1         // Decrementar contador Y
	cbnz x2,loop1       // Si no es la última fila, salto

///////////////////////////movimiento///////////////////////////

	// arco para el sol/luna, y = -1/256*x*x + 400, x23=x, x24=Y
	mov x12, #400							
	sub x23, x23, #2				// muevo x 4 pixeles a la derecha
	mul x11, x23, x23				// elevo x al cuadrado
	lsr x11, x11, #8				// divido x por 256
	sub x24, x12, x11				// y = 400 - x*x/256

	mov x11, xzr
	sub x11, x11, #385				// posicion x donde se deja de ver el sol/luna
	cmp x23, x11
	b.gt skip_cambio_hora			
		cmp x25, #0					// toggle que cambia de 0 a 1 o de 1 a 0 cuando se esconde el sol/luna respectivamente
		b.eq salto_dia			
		b salto_noche
		salto_dia:					// setea x25 en 1 si era 0
			mov x25, #1
			b ignore_salto_noche
		salto_noche:				// setea x25 en 0 si era 1
			mov x25, #0
		ignore_salto_noche:
		mov x23, #385				// mueve sol/luna a su posicion inicial
		mov x24, xzr
	skip_cambio_hora:


///////////////////////////detector de teclas///////////////////////////


	mov x3, GPIO_BASE

	// Atención: se utilizan registros w porque la documentación de broadcom
	// indica que los registros que estamos leyendo y escribiendo son de 32 bits

	// Setea gpios 0 - 9 como lectura
	str wzr, [x3, GPIO_GPFSEL0]

	// Lee el estado de los GPIO 0 - 31
	ldr w4, [x3, GPIO_GPLEV0]


	// And bit a bit mantiene el resultado del bit 2 en w10 (notar 0b... es binario)
	// al inmediato se lo refiere como "máscara" en este caso:
	// - Al hacer AND revela el estado del bit 2
	// - Al hacer OR "setea" el bit 2 en 1
	// - Al hacer AND con el complemento "limpia" el bit 2 (setea el bit 2 en 0)
																	// si w11 es 0 entonces el GPIO 1 estaba liberado
																	// de lo contrario será distinto de 0, (en este caso particular 2)
																	// significando que el GPIO 1 fue presionado	

	//w
	and w11, w4, 0b00000010                 // si w11 es distinto de cero, estoy tocando w										    									
	cbz w11, skip_w
		// tocar w
		add x19, x19, #1					    // alterna entre valores 0,1,2,3 de manera ascendiente
		cmp x19, #3
		b.le skip_loop_color_abajo				// si llega al 4 salta al 0
		mov x19, xzr
		skip_loop_color_abajo:
		// tocar w
	skip_w:

	//d

	and w11, w4, 0b00000100					// si w11 es distinto de cero, estoy tocando d
	cbz w11, skip_d
		//tocar d
		cmp x21, #260							// no moverse si sacaria al auto de la ruta
		b.gt skip_d
		add x21, x21, #4						// desplazar la coordenada x del auto 4 pixeles a la derecha
		//tocar d
	skip_d:

	//s

	and w11, w4, 0b00001000					// si w11 es distinto de cero, estoy tocando s
	cbz w11, skip_s
		//tocar s
		sub x19, x19, #1					    // alterna entre valores 3,2,1,0 de manera descendiente
		cmp x19, xzr
		b.ge skip_loop_color_arriba				// si llega al -1 salta al 3
		mov x19, #3
		skip_loop_color_arriba:
		//tocar s
	skip_s:

	//a

	and w11, w4, 0b00010000					// si w11 es distinto de cero, estoy tocando a
	cbz w11, skip_a
		// tocar a
		cmp x21, #80						    // no moverse si sacaria al auto de la ruta
		b.lt skip_a
		sub x21, x21, #4						// desplazar la coordenada x del auto 4 pixeles a la izquierda
		// tocar a
	skip_a:

	//espacio

	and w11, w4, 0b00100000					// si w11 es distinto de cero, estoy tocando espacio
	cbz w11, skip_espacio
		// tocar espacio
		cmp x27, xzr							// si x27 es 0 (esta en off) cuando toco espacio, cambio x27 a #1
		b.eq on
		mov x27, #0								// en caso que x27 no es 0 (esta en on) cuando toco espacio, lo cambio a 0
		b off
		on:
			mov x27, #1
		off:
		// tocar espacio
	skip_espacio:
	
	b redraw									// volver a dibujar toda la pantalla


///////////////////////////funciones///////////////////////////

	tiempo:                
		cmp x25, #0								
		b.eq color_sol						// si x25 = 0, usar el color sol
		b.ne color_luna						// si x25 = 1, usar el color luna
		ret
	
	sol_luna:               // X = x23, y=x24			// r^2 = (X-x)^2 + (Y-y)^2
		sub x9, x1, x5					// x9 = X-x, distancia entre la coordenada x del pixel seleccionado con la posicion central del circulo
		sub x11, x2, x6					// x11 = Y-y, distancia entre la coordenada y del pixel seleccionado con la posicion central del circulo
		mul x9, x9, x9					// x9 = (X-x)^2
		mul x11, x11, x11				// x11 = (Y-y)^2
		add x9, x9, x11					// x9 = (X-x)^2 + (Y-y)^2
		cmp x4, x9
		b.ge tiempo						// pinta en caso que r^2>=(X-x)^2 + (Y-y)^2 (todos los pixeles dentro del circulo de radio r centrado en X,Y)
		ret

	calle:						//X=525, Y=0		// paralelogramo con esquinas en (X,Y),(X-400,Y),(X-30,Y+120),(X-370,Y+120)
		sub x9, x5, x1					// x9 = 525 - x
		sub x11, x6, x2 				// x11 = 0 - y
		lsl x9, x9, #2					// x9 = (525-x)*4
		add x11, x11, x9				// x11 = -y + 4(525 - x)
		cmp x11, xzr															// esto "dibuja" una diagonal y=4(525-x) que pasa por y=0, x=525
		b.lt end_calle					// no pintar (0 - y) + 4(525 - x) < 0
		sub x9, x5, x1					// x9 = 525 - x
		sub x9, x9, x3					// x9 = (525-x)-410, muevo x 410 pixeles a la derecha
		sub x11, x6, x2  				// x11 = 0 - y
		lsl x9, x9, #2					// x9 = ((525-x)-410)*4
		sub x11, x11, x9				// x11 = y - 4(115-x)
		cmp x11, xzr													    	// esto "dibuja" una diagonal y=-4(115-x) que pasa por y=0, x=115 
		b.lt end_calle
		cmp x2, #120					// solo dibuja si me encuentro debajo de la altura y = 120
		b.le color_calle
		end_calle:
		ret																		// recordar que las diagonales son "invertidas" a una diagonal normal


	luz:                      			//mismo funcionamiento que codigo sol_luna
		sub x9, x5, x1
		sub x11, x6, x2
		mul x9, x9, x9
		mul x11, x11, x11
		add x9, x9, x11
		cmp x4, x9
		b.ge borde						// no pinta directamente sino que salta a borde
		ret

	borde:
		sub x4, x3, #5              	// vuelva a dibujar pero en un circulo con 5 pixeles menos de radio
		mul x4, x4, x4	
		sub x9, x5, x1
		sub x11, x6, x2
		mul x9, x9, x9
		mul x11, x11, x11
		add x9, x9, x11
		cmp x4, x9
		b.ge color_foco					// si entra en el circulo interno, pinta de color foco
		b.le color_borde				// si no entra en el circulo interno, pinta de color borde

	
	rectangulo: 
		sub x9, x5, x1					// x9 = X-x
		sub x11, x6, x2					// x11 = Y-y
		cmp x9, xzr						
		b.gt end_rectangulo				// si X>x no es parte del rectangulo
		cmp x11, xzr
		b.gt end_rectangulo				// si Y>y no es parte del rectangulo
		add x9, x5, x3					// x9 = X + l (longitud del rectangulo)
		add x11, x6, x4					// x11 = Y + h (altura del rectangulo)
		sub x9, x9, x1					// x9 = (X+l)-x
		sub x11, x11, x2				// x11 = (Y+h)-y
		cmp x9, xzr
		b.lt end_rectangulo				// si x>(X+l) no es parte del rectangulo
		cmp x11, xzr
		b.lt end_rectangulo				// si y>(Y+h) no es parte del rectangulo
		b color_auto_abajo				// si es parte del rectangulo entonces selecciona color
		end_rectangulo:
		ret


	paralelogramo_vacio:
		cmp x2, x6						// funciona igual que calle pero tiene un limite inferior
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
		b.lt end_paralelogramo_vacio	// solo lo que pertenece al paralologramo mayor continua

		add x9, x6, x7					// funciona igual que parelolgramo pero reduciendo el tamaño de los lados por el grosor dado
		cmp x2, x9
		b.le color_auto_arriba			// en caso de no pertencer al paralelogramo menor pero si al mayor, pinto de color_auto_arriba
		add x9, x6, x4
		sub x9, x9, x7
		cmp x2, x9
		b.gt color_auto_arriba			// en caso de no pertencer al paralelogramo menor pero si al mayor, pinto de color_auto_arriba
		sub x9, x5, x1
		sub x11, x6, x2 
		sub x9, x9, x7
		lsl x9, x9, #3
		add x11, x11, x9
		cmp x11, xzr
		b.le color_auto_arriba			// en caso de no pertencer al paralelogramo menor pero si al mayor, pinto de color_auto_arriba
		sub x9, x5, x1
		sub x9, x9, #300
		sub x11, x6, x2 
		add x9, x9, x7
		lsl x9, x9, #3
		sub x11, x11, x9
		cmp x11, xzr
		b.le color_auto_arriba				// en caso de no pertencer al paralelogramo menor pero si al mayor, pinto de color_auto_arriba
		b.gt color_vidrio					// en caso de pertencer al paralelogramo menor, pinta de color_vidrio
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
		b.le end_rectangulo_vacio		// solo lo que pertenece al rectangulo mayor continua

		sub x9, x5, x1
		sub x11, x6, x2
		add x9, x9, x7
		add x11, x11, x7
		cmp x9, xzr
		b.ge color_parrilla					// en caso de no pertencer al rectangulo menor pero si al mayor, pinta de color parrilla
		cmp x11, xzr
		b.ge color_parrilla					// en caso de no pertencer al rectangulo menor pero si al mayor, pinta de color parrilla
		add x12, x5, x3
		add x13, x6, x4
		sub x12, x12, x7
		sub x13, x13, x7
		sub x9, x11, x2
		sub x9, x12, x1
		sub x11, x13, x2
		cmp x9, xzr
		b.le color_parrilla					// en caso de no pertencer al rectangulo menor pero si al mayor, pinta de color parrilla
		cmp x11, xzr
		b.le color_parrilla					// en caso de no pertencer al rectangulo menor pero si al mayor, pinta de color parrilla
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

	       // 0x--RR (color rojo) 
		   // 0xGGBB (color verde y azul)
	color_foco:
		cmp x27, #1
		b.eq luz_prendida
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

		cmp x25, xzr
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
	color_calle:                  //		
		movz x10, 0x35, lsl 16
		movk x10, 0x373a, lsl 00     // w10 = fondo--color celeste (0x008fff)
		mov x9, x2
		lsr x9, x9, #1
		add x10, x10, x9
		ret
	color_pasto:                      //		
		movz x10, 0x0000, lsl 16
		movk x10, 0x9230, lsl 00     // w10 = fondo--color celeste (0x008fff)
		mov x9, x2
		lsr x9, x9, #2
		add x10, x10, x9
		ret
	color_sol:                       // sol_luna
		movz x10, 0x00FB, lsl 16
		movk x10, 0xC117, lsl 00     // w10 = circulo--color amarillo (0xFBC117)
		ret
	color_luna:                      // sol_luna
		movz x10, 0x00A2, lsl 16
		movk x10, 0xABB1, lsl 00     // w10 = circulo--color gris (0xA2ABB1)
		ret
	color_rueda: 
		movz x10, 0x001F, lsl 16
		movk x10, 0x1F1F, lsl 00     // w10 = circulo--color amarillo (0x909394)
		add x26, x26, #1
		cmp x26, #40
		b.ge gris
		end_gris:
		ret
		gris:
			mov x26, xzr
			movz x10, 0x004F, lsl 16
			movk x10, 0x4F4F, lsl 00     // w10 = circulo--color amarillo (0x909394)
			b end_gris
			
	color_borde:
		movz x10, 0x0010, lsl 16
		movk x10, 0x1314, lsl 00     // w10 = circulo--color amarillo (0x101314)
		ret

	color_auto_arriba:

		cmp x19, #1
		b.eq color_auto_arriba_amarillo
		cmp x19, #2
		b.eq color_auto_arriba_verde
		cmp x19, #3
		b.eq color_auto_arriba_azul
		movz x10, 0x00DF, lsl 16
		movk x10, 0x564A, lsl 00     // w10 = auto--color rojo (0xDF362A)
		ret

		color_auto_arriba_amarillo: #FDF77D
		movz x10, 0x00FD, lsl 16
		movk x10, 0xF77D, lsl 00     // w10 = auto--color rojo (0xDF362A)
		ret

		color_auto_arriba_verde: #A7E26E
		movz x10, 0x00A7, lsl 16
		movk x10, 0xE26E, lsl 00 
		ret

		color_auto_arriba_azul: #40A6E2
		movz x10, 0x0040, lsl 16
		movk x10, 0xA6E2, lsl 00 
		ret
	color_auto_abajo:
		cmp x19, #1
		b.eq color_auto_abajo_amarillo
		cmp x19, #2
		b.eq color_auto_abajo_verde
		cmp x19, #3
		b.eq color_auto_abajo_azul
		movz x10, 0x00DF, lsl 16
		movk x10, 0x362A, lsl 00     // w10 = auto--color rojo (0xDF362A)
		
		cmp x11, #15
		b.le color_auto_arriba
		sub x9, x4, x11
		lsr x9, x9, #1
		add x10, x10, x9
		lsl x9, x9, #8
		add x10, x10, x9
		ret

		color_auto_abajo_amarillo: #FCC118
		movz x10, 0x00FC, lsl 16
		movk x10, 0xC118, lsl 00     // w10 = auto--color rojo (0xDF362A)
		
		cmp x11, #15
		b.le color_auto_arriba
		sub x9, x4, x11
		lsr x9, x9, #1
		add x10, x10, x9
		lsl x9, x9, #8
		add x10, x10, x9
		ret


		color_auto_abajo_verde:
		movz x10, 0x0036, lsl 16
		movk x10, 0xDF2A, lsl 00     // w10 = auto--color rojo (0xDF362A)
		
		cmp x11, #15
		b.le color_auto_arriba
		sub x9, x4, x11
		lsr x9, x9, #1
		add x10, x10, x9
		lsl x9, x9, #17
		add x10, x10, x9
		ret


		color_auto_abajo_azul:
		movz x10, 0x002A, lsl 16
		movk x10, 0x36DF, lsl 00     // w10 = auto--color rojo (0xDF362A)
		cmp x11, #15
		b.le color_auto_arriba
		sub x9, x4, x11
		lsl x9, x9, #8
		add x10, x10, x9
		ret
	color_vidrio:	
		movz x10, 0x001f, lsl 16
		movk x10, 0x1f1f, lsl 00     // w10 = auto--color rojo (0x000000)
		sub x9, x2, x6
		lsr x9, x9, #1
		add x10, x10, x9
		ret

	color_parrilla:		#636363
		movz x10, 0x0063, lsl 16
		movk x10, 0x6363, lsl 00     // w10 = auto--color rojo (0x000000)
		ret

	//---------------------------------------------------------------
	// Infinite Loop
InfLoop:
	b InfLoop

