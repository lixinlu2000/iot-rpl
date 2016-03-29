//#undef RPL_CONF_DAG_MC
//#define RPL_CONF_DAG_MC RPL_DAG_MC_ETX

/* Configure Radio Transmission power
 *   - min     = m17dBm (-17dBm)
 *   - default = 0dBm
 *   - max     = 3dBm
 *   PHY_POWER_m10dBm
 *   PHY_POWER_0dBm
 */
#define RF2XX_TX_POWER PHY_POWER_m17dBm

/* Configure Radio Transmission power
 *   - min     = m101Bm (-101dBm)
 *   - default = m101dBm
 *   - max     = m48dBm (-48dBm)
 * To see all the valid values see `enum rf2xx_phy_rx_threshold` in
 *     openlab/periph/rf2xx/rf2xx_regs.h
 */
#define RF2XX_RX_RSSI_THRESHOLD  RF2XX_PHY_RX_THRESHOLD__m72dBm

#define RPL_CONF_OF rpl_of0
//#define RPL_CONF_GROUNDED	1

//#define RPL_CONF_MOP	RPL_MOP_NO_DOWNWARD_ROUTES

// default 12, ietf 3
//#undef RPL_CONF_DIO_INTERVAL_MIN
//#define RPL_CONF_DIO_INTERVAL_MIN 6

// default 8, ietf 20=2.3 hr
//#undef RPL_CONF_DIO_INTERVAL_DOUBLINGS
//#define RPL_CONF_DIO_INTERVAL_DOUBLINGS 14

//#undef NETSTACK_CONF_RDC_CHANNEL_CHECK_RATE
//#define NETSTACK_CONF_RDC_CHANNEL_CHECK_RATE 16
