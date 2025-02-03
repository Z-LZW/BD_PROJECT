`ifndef APB_TYPES_GUARD
`define APB_TYPES_GUARD

typedef enum bit {APB_MASTER, APB_SLAVE}       apb_agent_kind_t;
typedef enum bit {APB_WRITE, APB_READ}         apb_trans_kind_t;
typedef enum bit {APB_OKAY, APB_ERROR}         apb_trans_resp_t;
typedef enum {ZERO, SHORT, MEDIUM, LARGE, MAX} apb_delay_kind_t;

`endif