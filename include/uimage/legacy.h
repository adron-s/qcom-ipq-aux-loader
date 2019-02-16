#ifndef __LEGACY_H__
#define __LEGACY_H__

#define LEGACY_IH_MAGIC	0x27051956	/* LEGACY Magic Number		*/
#define LEGACY_IH_NMLEN		32	/* LEGACY Name Length		*/

/*
 * Legacy format LEGACY header,
 * all data in network byte order (aka natural aka bigendian).
 */
typedef struct legacy_image_header {
	uint32_t	ih_magic;	/* LEGACY Header Magic Number	*/
	uint32_t	ih_hcrc;	/* LEGACY Header CRC Checksum	*/
	uint32_t	ih_time;	/* LEGACY Creation Timestamp	*/
	uint32_t	ih_size;	/* LEGACY Data Size		*/
	uint32_t	ih_load;	/* Data	 Load  Address		*/
	uint32_t	ih_ep;		/* Entry Point Address		*/
	uint32_t	ih_dcrc;	/* LEGACY Data CRC Checksum	*/
	uint8_t		ih_os;		/* Operating System		*/
	uint8_t		ih_arch;	/* CPU architecture		*/
	uint8_t		ih_type;	/* LEGACY Type			*/
	uint8_t		ih_comp;	/* Compression Type		*/
	uint8_t		ih_name[LEGACY_IH_NMLEN];	/* LEGACY Name		*/
} legacy_image_header_t;

#endif	/* __LEGACY_H__ */
