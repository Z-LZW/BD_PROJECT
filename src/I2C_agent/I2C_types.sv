`ifndef I2C_TYPES_GUARD
`define I2C_TYPES_GUARD

typedef enum bit {I2C_SLAVE, I2C_MASTER} i2c_agent_kind_t;
typedef enum bit {I2C_READ, I2C_WRITE}   i2c_trans_kind_t;
typedef enum bit {I2C_ACK, I2C_NACK}     i2c_resp_kind_t ;

`endif