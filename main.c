/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xil_types.h"
#include "../../design_1_wrapper_hw_platform_0/drivers/bubble_sort_v1_0/src/bubble_sort.h"
#include "xparameters.h"

#define k 100 //k numbers to be sorted

int main()
{
	init_platform();
	unsigned int i;

	int num_array[100] = {	 0,  2,  7,  8, 1,
							-4, -3, -2, -1, -77,
							56, 404, -22323, -232, -3249,
							2324, 384, -384, -32, -1,
							-33434, 23674, -293, 9234, 12,
							23, 45, 66767, 3845, -123,
							-92, -56, -43, 5666, 567,
							-1, -2, -3, -4, -5,
							999, 201, -2947, -4756, -2233,
							-2, -4444, -56, 012, 45,
							-65, -7, 129, 567, 2326,
							875, -6897, 23, 756, 98,
							-5956, -938, 32434, 655, 6,
							-234, -45555, 54444, 56, 65,
							343434, 455666, -5445646, 454656, 455,
							658, 876, 2948, 986, 045,
							47657, 5886, 465, 89554, 545,
							578, 67, 54, 22, 123,
							455, 667, 54, 123, 455,
							46578, 586, 48456, 923, -100000000
						};
	//------------------------------------------------------------------
	// reset slv_reg1(0)
	//------------------------------------------------------------------
	BUBBLE_SORT_mWriteReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR, 4, 0x1);
	BUBBLE_SORT_mWriteReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR, 4, 0x0);
	printf("device reset\n\r");
	printf("List\n\r");
	//------------------------------------------------------------------
	// go download slv_reg1(1)
	//----------------------------------------------------------------
	BUBBLE_SORT_mWriteReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR, 4, 0x2);
	// device waits on go low
	BUBBLE_SORT_mWriteReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR, 4, 0x0);
	//------------------------------------------------------------------
	// download data: new_data: slv_reg3(0), data_put is bus2ip_w_ack
	// wait on new_data, data_put=1, wait on !new_data, data_put=0
	//------------------------------------------------------------------
	for (i=0;i<k;i++) {
	// wait on new data = 1
	while ((unsigned int)	(BUBBLE_SORT_mReadReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR,12)&0x00000001)==0);

	// write data
	BUBBLE_SORT_mWriteReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR, 0, num_array[i]);
	// bus2ip_w_ack = 1 slv_reg1(2)
	BUBBLE_SORT_mWriteReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR, 4, 0x4);
	// wait on new data = 0
	while ((unsigned int)(BUBBLE_SORT_mReadReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR,12)&0x00000001)==1);
	// bus2ip_w_ack = 0
	BUBBLE_SORT_mWriteReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR, 4, 0x0);
	if (i%5 == 4)
		printf("%d\n\r",(unsigned int)BUBBLE_SORT_mReadReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR,0));
	else
		printf("%d    ",(unsigned int)BUBBLE_SORT_mReadReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR,0));
	}
	//--------------------------------------------------------------------------------
	// wait on done sorting flag slv_reg3(1)
	//--------------------------------------------------------------------------------
	while ((unsigned int)(BUBBLE_SORT_mReadReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR,12)&0x00000002)==0);

	printf("done run \n\r");
	////--------------------------------------------------------------------
	// go upload slv_reg1(1)
	////--------------------------------------------------------------------
	BUBBLE_SORT_mWriteReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR, 4, 0x2);
	// wait on done low
	while ((unsigned int)(BUBBLE_SORT_mReadReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR,12)&0x00000002)==1);
	// device waits on go low// device waits on go low
	BUBBLE_SORT_mWriteReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR, 4, 0x0);
	printf("Sorted List\n\r");
	//--------------------------------------------------------------------
	// upload: wait on new data slv_reg3(0)
	// read acknowledge is bus2ip_r_ack; slv_reg1(3)
	//--------------------------------------------------------------------
	// bus2ip_r_ack = 0
	BUBBLE_SORT_mWriteReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR, 4, 0x0);
	for (i=0;i<k;i++) {
	// wait on new data = 1
	while((unsigned int)(BUBBLE_SORT_mReadReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR,12)&0x00000001)==0);
	// print result
	if (i%5 == 4)
		printf("%d\n\r" ,(unsigned int)	BUBBLE_SORT_mReadReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR,8));
	else
		printf("%d  ",(unsigned int)BUBBLE_SORT_mReadReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR,8));
	// bus2ip_r_ack = 1
	BUBBLE_SORT_mWriteReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR, 4, 0x8);
	// wait on new data = 0
	while ((unsigned int)	(BUBBLE_SORT_mReadReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR,12)&0x00000001)==1);
	// bus2ip_r_ack = 0
	BUBBLE_SORT_mWriteReg(XPAR_BUBBLE_SORT_0_S00_AXI_BASEADDR, 4, 0x0);
	}
	printf("chill\n\r");

	return 0;
}
