# =============================================================================
# risc.sdc - Restricoes de timing (TimeQuest) para o projeto com IP ALTPLL.
#
# CLK e a ENTRADA de referencia da PLL. A PLL (megafuncao ALTPLL) gera:
#   c0 = CLK_SYS  e  c1 = CLK_MUL.
# 'derive_pll_clocks' cria automaticamente os clocks de saida da PLL a partir
# dos parametros do IP (multiply/divide), entao o TimeQuest analisa CADA
# dominio (CLK_SYS e CLK_MUL) separadamente e reporta a Fmax correta por dominio.
#
# IMPORTANTE: ajuste o -period de CLK para o MESMO periodo de entrada definido
# no IP Catalog (inclk0_input_frequency). Aqui: 4 ns = 250 MHz.
# =============================================================================
create_clock -name CLK -period 4.000 [get_ports CLK]

# cria CLK_SYS (c0) e CLK_MUL (c1) a partir dos parametros do IP ALTPLL
derive_pll_clocks
derive_clock_uncertainty

# Os sinais St (CLK_SYS->CLK_MUL) e Done (CLK_MUL->CLK_SYS) cruzam dominios por
# sincronizadores de 2 FF (CDC). Esses caminhos sao assincronos por construcao
# e NAO devem ser analisados como caminhos sincronos -> false_path entre os dois
# clocks da PLL (evita Fmax falsamente baixa por caminhos inter-dominio).
set_false_path -from [get_clocks {*|altpll_component|*clk[0]}] \
               -to   [get_clocks {*|altpll_component|*clk[1]}]
set_false_path -from [get_clocks {*|altpll_component|*clk[1]}] \
               -to   [get_clocks {*|altpll_component|*clk[0]}]

# barramentos externos / reset assincrono sem restricao critica
set_false_path -from [get_ports {rst}]
