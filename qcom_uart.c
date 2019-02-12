#include "iomap.h"
#include "io.h"


/* Number of characters for Transmission */
#define MSM_BOOT_UART_DM_NO_CHARS_FOR_TX(base) ((base) + 0x040)

/*UART General Command */
#define MSM_BOOT_UART_DM_CR_GENERAL_CMD(x)   ((x) << 8)

#define MSM_BOOT_UART_DM_GCMD_NULL            MSM_BOOT_UART_DM_CR_GENERAL_CMD(0)
#define MSM_BOOT_UART_DM_GCMD_CR_PROT_EN      MSM_BOOT_UART_DM_CR_GENERAL_CMD(1)
#define MSM_BOOT_UART_DM_GCMD_CR_PROT_DIS     MSM_BOOT_UART_DM_CR_GENERAL_CMD(2)
#define MSM_BOOT_UART_DM_GCMD_RES_TX_RDY_INT  MSM_BOOT_UART_DM_CR_GENERAL_CMD(3)
#define MSM_BOOT_UART_DM_GCMD_SW_FORCE_STALE  MSM_BOOT_UART_DM_CR_GENERAL_CMD(4)
#define MSM_BOOT_UART_DM_GCMD_ENA_STALE_EVT   MSM_BOOT_UART_DM_CR_GENERAL_CMD(5)
#define MSM_BOOT_UART_DM_GCMD_DIS_STALE_EVT   MSM_BOOT_UART_DM_CR_GENERAL_CMD(6)

/* UART Command Register */
#if PERIPH_BLK_BLSP
#define MSM_BOOT_UART_DM_CR(base)              ((base) + 0xA8)
#else
#define MSM_BOOT_UART_DM_CR(base)              ((base) + 0x10)
#endif
#define MSM_BOOT_UART_DM_CR_RX_ENABLE        (1 << 0)
#define MSM_BOOT_UART_DM_CR_RX_DISABLE       (1 << 1)
#define MSM_BOOT_UART_DM_CR_TX_ENABLE        (1 << 2)
#define MSM_BOOT_UART_DM_CR_TX_DISABLE       (1 << 3)

/* UART Status Register */
#if PERIPH_BLK_BLSP
#define MSM_BOOT_UART_DM_SR(base)              ((base) + 0x0A4)
#else
#define MSM_BOOT_UART_DM_SR(base)              ((base) + 0x008)
#endif
#define MSM_BOOT_UART_DM_SR_RXRDY            (1 << 0)
#define MSM_BOOT_UART_DM_SR_RXFULL           (1 << 1)
#define MSM_BOOT_UART_DM_SR_TXRDY            (1 << 2)
#define MSM_BOOT_UART_DM_SR_TXEMT            (1 << 3)
#define MSM_BOOT_UART_DM_SR_UART_OVERRUN     (1 << 4)
#define MSM_BOOT_UART_DM_SR_PAR_FRAME_ERR    (1 << 5)
#define MSM_BOOT_UART_DM_RX_BREAK            (1 << 6)
#define MSM_BOOT_UART_DM_HUNT_CHAR           (1 << 7)
#define MSM_BOOT_UART_DM_RX_BRK_START_LAST   (1 << 8)

/* UART DM TX FIFO Registers - 4 */
#if PERIPH_BLK_BLSP
#define MSM_BOOT_UART_DM_TF(base, x)         ((base) + 0x100+(4*(x)))
#else
#define MSM_BOOT_UART_DM_TF(base, x)         ((base) + 0x70+(4*(x)))
#endif

/* UART Interrupt Status Register */
#if PERIPH_BLK_BLSP
#define MSM_BOOT_UART_DM_ISR(base)          ((base) + 0xB4)
#else
#define MSM_BOOT_UART_DM_ISR(base)          ((base) + 0x14)
#endif

#define MSM_BOOT_UART_DM_TXLEV               (1 << 0)
#define MSM_BOOT_UART_DM_RXHUNT              (1 << 1)
#define MSM_BOOT_UART_DM_RXBRK_CHNG          (1 << 2)
#define MSM_BOOT_UART_DM_RXSTALE             (1 << 3)
#define MSM_BOOT_UART_DM_RXLEV               (1 << 4)
#define MSM_BOOT_UART_DM_DELTA_CTS           (1 << 5)
#define MSM_BOOT_UART_DM_CURRENT_CTS         (1 << 6)
#define MSM_BOOT_UART_DM_TX_READY            (1 << 7)
#define MSM_BOOT_UART_DM_TX_ERROR            (1 << 8)
#define MSM_BOOT_UART_DM_TX_DONE             (1 << 9)
#define MSM_BOOT_UART_DM_RXBREAK_START       (1 << 10)
#define MSM_BOOT_UART_DM_RXBREAK_END         (1 << 11)
#define MSM_BOOT_UART_DM_PAR_FRAME_ERR_IRQ   (1 << 12)

void serial_putc(char c){
	unsigned int base = UART1_DM_BASE;
	unsigned int num_of_chars = 1;
	unsigned int tx_word = 0;
	/* We are here. FIFO is ready to be written. */
	/* Write number of characters to be written */
	writel(num_of_chars, MSM_BOOT_UART_DM_NO_CHARS_FOR_TX(base));

	/* Clear TX_READY interrupt */
	writel(MSM_BOOT_UART_DM_GCMD_RES_TX_RDY_INT, MSM_BOOT_UART_DM_CR(base));

	/* Wait till TX FIFO has space */
	while(!(readl(MSM_BOOT_UART_DM_SR(base)) & MSM_BOOT_UART_DM_SR_TXRDY));
	if(c == '\n'){
		/* Replace linefeed char "\n" with carriage return + linefeed "\r\n". */
		/* tx_word = '\r';
		tx_word <<= 8;
		tx_word |= '\n'; */
		tx_word = c; /* We need only one char */
	}else{
		tx_word = c; /* We need only one char */
	}
	/* TX FIFO has space. Write the chars */
	writel(tx_word, MSM_BOOT_UART_DM_TF(base, 0));
}
