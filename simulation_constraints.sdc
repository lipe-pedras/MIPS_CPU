# Cria um clock de teste para o sistema (ex: 100 MHz / período de 10ns)
create_clock -name sys_clk -period 10.0 [get_ports {CLK_SYS}]

# Cria um clock de teste para o multiplicador (ex: 500 MHz / período de 2ns)
create_clock -name mul_clk -period 2.0 [get_ports {CLK_MUL}]

# Diz ao Quartus que os clocks são independentes e ele não deve analisar
# o tempo de setup/hold dos sinais que viajam entre eles (ex: St e Done)
set_clock_groups -asynchronous -group {sys_clk} -group {mul_clk}