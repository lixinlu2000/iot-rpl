/*
 * This file is part of the Contiki operating system.
 */
/**
 * \author Xinlu <xinlu.li@mydit.ie>
 */

#include "contiki.h"
#include "lib/random.h"
#include "sys/ctimer.h"
#include "net/uip-ds6.h"
#include "net/uip.h"
#include "net/uip-udp-packet.h"
#include "sys/ctimer.h"
#include "net/rpl/rpl.h"

#include "powertrace.h"

#include <stdio.h>
#include <string.h>
#include "rpl-evaluation.h"

#define UDP_CLIENT_PORT 8765
#define UDP_SERVER_PORT 5678

#define UDP_EXAMPLE_ID  190

#define DEBUG DEBUG_PRINT
#include "net/uip-debug.h"

#ifndef PERIOD
#define PERIOD 60
#endif

#define START_INTERVAL		(15 * CLOCK_SECOND)
#define SEND_INTERVAL		(PERIOD * CLOCK_SECOND)
#define SEND_TIME		(random_rand() % (SEND_INTERVAL))
#define MAX_PAYLOAD_LEN		30

static struct uip_udp_conn *client_conn;
static uip_ipaddr_t server_ipaddr;

/*---------------------------------------------------------------------------*/
PROCESS(udp_client_process, "UDP client process");
AUTOSTART_PROCESSES(&udp_client_process);
/*---------------------------------------------------------------------------*/
static void
tcpip_handler(void)
{
  //char *str;
  if(uip_newdata()) {
	  //do nothing, we are client!
  }
}
/*---------------------------------------------------------------------------*/
/* print the preferred parent and neighbor node for current node. */
static void
common_net_print()
{
	rpl_dag_t *dag;
	rpl_parent_t *preferred_parent;
	uip_ds6_route_t *r;

	/* Let's suppose we have only one instance */
	dag = rpl_get_any_dag();
	if(dag->preferred_parent != NULL) {
	   PRINTF("Preferred parent: ");
	   PRINT6ADDR(rpl_get_parent_ipaddr(dag->preferred_parent));
	   PRINTF("  Preferred parent Rank: %d",dag->preferred_parent->rank);
	   PRINTF("\n");
	 }

	for(r = uip_ds6_route_head();
	    r != NULL;
	    r = uip_ds6_route_next(r)) {
	    PRINT6ADDR(&r->ipaddr);
	    PRINTF("  ");
	}
	  PRINTF("\n");
}
/*---------------------------------------------------------------------------*/
static void
send_packet(void *ptr)
{
	struct data_msg msg;
	static uint8_t seqno;
	uint16_t rank;
	uint16_t num_neighbors;

	rpl_dag_t *dag;

	memset(&msg,0,sizeof(msg));
	seqno++;
	msg.seqno = seqno;
	//linkaddr_copy(&parent, &linkaddr_null);

	/* Let's suppose we have only one instance */
	dag = rpl_get_any_dag();
	/*
	if(dag !=NULL) {
		preferred_parent = dag->preferred_parent;
		if(preferred_parent != NULL) {
			uip_ds6_nbr_t *nbr;
			nbr = uip_ds6_nbr_lookup(rpl_get_parent_ipaddr(preferred_parent));
			if(nbr !=NULL){
				/* USE parts of the IPV6 address as the parent address, in reversed byte order. */
/*		        parent.u8[LINKADDR_SIZE - 1] = nbr->ipaddr.u8[sizeof(uip_ipaddr_t) - 2];
		        parent.u8[LINKADDR_SIZE - 2] = nbr->ipaddr.u8[sizeof(uip_ipaddr_t) - 1];
		        parent_etx = rpl_get_parent_rank((uip_lladdr_t *) uip_ds6_nbr_get_ll(nbr)) / 2;
			}
		}
		*/
		rank = dag->rank;
		num_neighbors = uip_ds6_nbr_num();
	/*} else {
		rank = 0;
		num_neighbors = 0;
	}*/
	msg.len = sizeof(struct data_msg) / sizeof(uint16_t);
	msg.clock = clock_time();

	msg.rank = rank;
	msg.num_neighbors = num_neighbors;
	PRINTF("DATA send to %d: ",server_ipaddr.u8[sizeof(server_ipaddr.u8) - 1]);
	PRINTF("seqno: %d, len: %d, clock: %u, rank: %d, num_neighbors: %d \n",
			msg.seqno,msg.len,msg.clock,msg.rank,msg.num_neighbors);

	//common_net_print();

	uip_udp_packet_sendto(client_conn, &msg, sizeof(msg),
	                        &server_ipaddr, UIP_HTONS(UDP_SERVER_PORT));
}
/*---------------------------------------------------------------------------*/
static void
print_local_addresses(void)
{
  int i;
  uint8_t state;

  PRINTF("Client IPv6 addresses: ");
  for(i = 0; i < UIP_DS6_ADDR_NB; i++) {
    state = uip_ds6_if.addr_list[i].state;
    if(uip_ds6_if.addr_list[i].isused &&
       (state == ADDR_TENTATIVE || state == ADDR_PREFERRED)) {
      PRINT6ADDR(&uip_ds6_if.addr_list[i].ipaddr);
      PRINTF("\n");
      /* hack to make address "final" */
      if (state == ADDR_TENTATIVE) {
	uip_ds6_if.addr_list[i].state = ADDR_PREFERRED;
      }
    }
  }
}
/*---------------------------------------------------------------------------*/
static void
set_global_address(void)
{
  uip_ipaddr_t ipaddr;

  uip_ip6addr(&ipaddr, 0xaaaa, 0, 0, 0, 0, 0, 0, 0);
  uip_ds6_set_addr_iid(&ipaddr, &uip_lladdr);
  uip_ds6_addr_add(&ipaddr, 0, ADDR_AUTOCONF);

/* The choice of server address determines its 6LoPAN header compression.
 * (Our address will be compressed Mode 3 since it is derived from our link-local address)
 * Obviously the choice made here must also be selected in udp-server.c.
 *
 * For correct Wireshark decoding using a sniffer, add the /64 prefix to the 6LowPAN protocol preferences,
 * e.g. set Context 0 to aaaa::.  At present Wireshark copies Context/128 and then overwrites it.
 * (Setting Context 0 to aaaa::1111:2222:3333:4444 will report a 16 bit compressed address of aaaa::1111:22ff:fe33:xxxx)
 *
 * Note the IPCMV6 checksum verification depends on the correct uncompressed addresses.
 */
 
#if 0
/* Mode 1 - 64 bits inline */
   uip_ip6addr(&server_ipaddr, 0xaaaa, 0, 0, 0, 0, 0, 0, 1);
#elif 1
/* Mode 2 - 16 bits inline */
  uip_ip6addr(&server_ipaddr, 0xaaaa, 0, 0, 0, 0, 0x00ff, 0xfe00, 1);
#else
/* Mode 3 - derived from server link-local (MAC) address */
  uip_ip6addr(&server_ipaddr, 0xaaaa, 0, 0, 0, 0x0250, 0xc2ff, 0xfea8, 0xcd1a); //redbee-econotag
#endif
}
/*---------------------------------------------------------------------------*/
PROCESS_THREAD(udp_client_process, ev, data)
{
  static struct etimer periodic;
  static struct ctimer backoff_timer;


  PROCESS_BEGIN();

  /* Start powertracing, once every 60 seconds. */
  //powertrace_start(CLOCK_SECOND * 60);

  PROCESS_PAUSE();

  set_global_address();
  
  PRINTF("UDP client process started\n");

  print_local_addresses();

  /* new connection with remote host */
  client_conn = udp_new(NULL, UIP_HTONS(UDP_SERVER_PORT), NULL); 
  if(client_conn == NULL) {
    PRINTF("No UDP connection available, exiting the process!\n");
    PROCESS_EXIT();
  }
  udp_bind(client_conn, UIP_HTONS(UDP_CLIENT_PORT)); 

  PRINTF("Created a connection with the server ");
  PRINT6ADDR(&client_conn->ripaddr);
  PRINTF(" local/remote port %u/%u\n",
	UIP_HTONS(client_conn->lport), UIP_HTONS(client_conn->rport));

  etimer_set(&periodic, SEND_INTERVAL);
  while(1) {
    PROCESS_YIELD();
    if(ev == tcpip_event) {
      tcpip_handler();
    }
    
    if(etimer_expired(&periodic)) {
      etimer_reset(&periodic);
      ctimer_set(&backoff_timer, SEND_TIME, send_packet, NULL);

    }
  }

  PROCESS_END();
}
/*---------------------------------------------------------------------------*/
