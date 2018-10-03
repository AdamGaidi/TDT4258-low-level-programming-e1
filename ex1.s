        .syntax unified

	      .include "efm32gg.s"

	/////////////////////////////////////////////////////////////////////////////
	//
  // Exception vector table
  // This table contains addresses for all exception handlers
	//
	/////////////////////////////////////////////////////////////////////////////

        .section .vectors

	      .long   stack_top               /* Top of Stack                 */
	      .long   _reset                  /* Reset Handler                */
	      .long   dummy_handler           /* NMI Handler                  */
	      .long   dummy_handler           /* Hard Fault Handler           */
	      .long   dummy_handler           /* MPU Fault Handler            */
	      .long   dummy_handler           /* Bus Fault Handler            */
	      .long   dummy_handler           /* Usage Fault Handler          */
	      .long   dummy_handler           /* Reserved                     */
	      .long   dummy_handler           /* Reserved                     */
	      .long   dummy_handler           /* Reserved                     */
	      .long   dummy_handler           /* Reserved                     */
	      .long   dummy_handler           /* SVCall Handler               */
	      .long   dummy_handler           /* Debug Monitor Handler        */
	      .long   dummy_handler           /* Reserved                     */
	      .long   dummy_handler           /* PendSV Handler               */
	      .long   dummy_handler           /* SysTick Handler              */

	      /* External Interrupts */
	      .long   dummy_handler
	      .long   gpio_handler            /* GPIO even handler */
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   gpio_handler            /* GPIO odd handler */
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler
	      .long   dummy_handler



	      .section .text

	/////////////////////////////////////////////////////////////////////////////
	//
  // Reset handler
  // The CPU will start executing here after a reset
	//
	/////////////////////////////////////////////////////////////////////////////

	      .globl  _reset
	      .type   _reset, %function
        .thumb_func
_reset:

		//--- Adjust processor clock frequency ---
		
		//Lower HFCLK (high frequency clock)
		ldr r0, =CMU_BASE
		ldr r1, =0x1c000 //Divide current HFCLK frequency by 7 + 1
		str r1, [r0] //CMU_CTRL is at the start of CMU_BASE register, thus no need for offset
		
		//Lower HFCORECLK (high frequency core clock)
		ldr r0, =CMU_BASE
		ldr r1, =0x9 //Divide current HFCORECLK frequency by 512
		str r1, [r0, #CMU_HFCORECLK]
		
		//--- Disable unused SRAM blocks ---
		
		//Disable blocks 1-2 by writing 3 to EMU_MEMCTRL
		ldr r2, =EMU_BASE
		mov r3, #0x3
		str r3, [r2, #EMU_MEMCTRL]

        //--- Enable GPIO clock in CMU ---

		//Load CMU_BASE register and HFPERCLK from offset
        ldr r0, =CMU_BASE
        ldr r1, [r0, #CMU_HFPERCLKEN0]

        //Set enable
        mov r2, #1
        lsl r2, r2, #CMU_HFPERCLKEN0_GPIO
        orr r1, r1, r2

		//Store new value with GPIO clock enabled
        str r1, [r0, #CMU_HFPERCLKEN0]
        

        //--- Set lowest drive strength ---
		
		//Load GPIO_PA_BASE and GPIO_PA_CTRL from offset
        ldr r0, =GPIO_PA_BASE
        ldr r1, [r0, #GPIO_CTRL]

        //Write 0x1 to GPIO_PA_CTRL to enable lowest drive strength
        mov r2, #1
        orr r1, r1, r2
		
		//Store new value with lowest drive strength enabled
        str r1, [r0, #GPIO_CTRL]
        

    	//--- Set pins 8-15 (LEDs) to output ---

    	//Write 0x55555555 to GPIO_PA_MODEH
    	mov r2, #0x55555555
    	str r2, [r0, #GPIO_MODEH]

    	//Pins 8-15 can now be set high or low by writing to bits 8-15 of GPIO_PA_DOUT.


    	//--- Set pins 0-7 (buttons) to input ---

    	ldr r0, =GPIO_PC_BASE

   		//Write 0x33333333 to GPIO_PC_MODEL
    	mov r2, #0x33333333
    	str r2, [r0, #GPIO_MODEL]

    	//Enable internal pull-up by writing 0xff to GPIO_PC_DOUT
    	mov r2, #0xff
    	str r2, [r0, #GPIO_DOUT]

    	//Status of pins 0-7 can now be found by reading GPIO_PC_DIN
		

        //--- Interrupt setup ---
	
		//Enable interrupts for pins 0-7 on port C (buttons)
		ldr r0, =GPIO_BASE
		mov r1 , #0x22222222
		str r1, [r0, #GPIO_EXTIPSELL]
		mov r1, #0xff
        str r1, [r0, #GPIO_IEN]
		str r1, [r0, #GPIO_EXTIFALL]

		//Clear interrupt flags
		ldr r1, [r0, #GPIO_IF] // Determine source of interupt
		str r1, [r0, #GPIO_IFC] // Clear flags
	
		//Enable interupt handling
		ldr r2, =0x802
		ldr r3, =ISER0
		str r2, [r3]
		
		
		//--- Set deep-sleep mode ---
		
        mov r7, #0x6
        ldr r8, =SCR
        str r7, [r8]
		
		
		//--- Activate initial light ---
		
		mov r7,  #0b01111111
        lsl r6, r7, #8
        ldr r0, =GPIO_PA_BASE
        str r6, [r0, #GPIO_DOUT]
	

//Main loop: When no interrupts -> Wait for interrupt (wfi)

sleep:
        wfi
        b sleep


	/////////////////////////////////////////////////////////////////////////////
	//
  // GPIO handler
  // The CPU will jump here when there is a GPIO interrupt
	//
	/////////////////////////////////////////////////////////////////////////////

        .thumb_func
gpio_handler:
		ldr r1, =GPIO_PC_BASE
		ldr r4, [r1, #GPIO_DIN]

        //Invert input to match the pattern: Button pressed -> 1
        mov r2, #0b11111111
        eor r4, r2, r4
        mov r6, #0 //Used to check if buttons was pressed

        //Test if leftbutton was pressed
		mov r5, #0b00010001 //Bit 0 and 4 correspond to buttons SW1,SW5
		and r5, r4, r5

        cmp r6, r5
        
        blt if_leftbutton
        b test_right
        
        //Leftbutton rightshifts and rightbutton leftshifts because the most significant led is in the rightmost position.
        
if_leftbutton:
        mov r8, #0b100000000 //Random values in the 9.+ bit should not interfere
        orr r7, r7, r8
        lsr r7, r7, #1  //Rightshift the current value (Divide by 2)
        b gp_out

test_right:
        mov r5, #0b01000100 //Bit 2 and 6 correspond to buttons SW3, SW7
        and r5, r5, r4

        cmp r6, r5
        blt if_rightbutton
        b test_up

if_rightbutton:
        lsl r7, r7, #1 //Leftshift current value (Multiply by 2)
        mov r8, #0b00000001
        add r7, r7, r8 //Ensure that bit 0 does not randomly light up by adding 1
        b gp_out

test_up:
        mov r5, #0b00100010 //Bit 1 and 5 correspond to buttons SW2, SW6
        and r5, r5, r4


        cmp r6, r5
        blt if_upbutton
        b test_down

if_upbutton:
        //Because lights are active low the logic is reversed: Subtracting 1 = Increment by 1
        mov r8, #0b00000001
        sub r7, r7, r8
        b gp_out

test_down:
        mov r5, #0b10001000 //Bit 3 and 7 correspond to buttons SW4, SW8
        and r5, r5, r4

        cmp r6, r5
        blt if_downbutton
        b gp_out

if_downbutton:
        //Because lights are active low the logic is reversed: Adding 1 = Decrement by 1
        mov r8, #0b00000001
        add r7, r7, r8
        b gp_out

gp_out:
        //Output result from interrupt to LED lights
		lsl r6, r7, #8
		ldr r1, =GPIO_PA_BASE
		str r6, [r1, #GPIO_DOUT]

		//Clear interrupt flags
		ldr r1, =GPIO_BASE
		ldr r2, [r1, #GPIO_IF] //Determine source of interupt
		str r2, [r1, #GPIO_IFC] //Clear flags
		bx lr //Return pc to location prior to interrupt
	
	
	////////////////////////////////////////////////////////////////
	
        .thumb_func
dummy_handler:
        b .  // do nothing



