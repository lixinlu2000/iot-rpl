#ifndef RPL_EVALUATION_H
#define RPL_EVALUATION_H

struct data_msg {

      uint8_t seqno;
      //uint8_t for_alignment;
	  uint16_t len;
	  uint16_t clock;
	  //uint16_t parent;
	  //uint16_t parent_etx;
	  uint16_t rank;
	  uint16_t num_neighbors;
	  uip_ipaddr_t client_ipaddr;
} data_msg;

#endif /* RPL_EVALUATION_H */
