# TDT4258-low-level-programming-e1
This project was written for the EFM32GG DK3750 Development Board, with a custom gamepad which has 8 LED lights, and 8 buttons. 

The part of the exercise solution uploaded to this repo is a simple binary calculator with input read through interrupts from the button inputs. The LED lights on the gamepad each represent one bit in an 8-bit number. The up and down buttons add and subtract 1 from the number, whilethe left and right buttons multiply and divide by 2.  If any bit either under- or overflowsthe  scope  of  an  8-bit  number,  it  is  simply  lost.   Eg:   Applying  multiplication  to  thenumber 0b10000000 will cause the MSB to overflow and the resulting number will be0b00000000

This solution is interrupt based, where the main method simply executes a 'wait-for-interrupt'-instruction. When an interrupt flag is triggered, the gpio_handler is called. This is done through the make file (Not uploaded) and vector-table at the start of the file 'ex1.s'. 

Power saving methods which are implemented:
* Reduced Clock frequency
* Lowered LED-strength
* Disabling of unused SRAM blocks
* Interrupt based, as opposed to a polling based solution
* Deep Sleep Mode activated
