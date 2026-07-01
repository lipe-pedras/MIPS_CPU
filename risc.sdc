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
# no IP Catalog (inclk0_input_frequency). Aqui: 4.27 ns = 234.19 MHz (freq
# reduzida para o caminho do produto do MUL fechar setup em Slow 85C, sem FF).
# =============================================================================
create_clock -name CLK -period 4.270 [get_ports CLK]

# cria CLK_SYS (c0) e CLK_MUL (c1) a partir dos parametros do IP ALTPLL
derive_pll_clocks
derive_clock_uncertainty

# CLK_SYS (c0) e CLK_MUL (c1) vem da MESMA PLL, com razao INTEIRA (34:1) e fase
# controlada -> sao clocks SINCRONOS RELACIONADOS, NAO dominios assincronos.
# Por isso NAO usamos false_path (nem sincronizadores de 2 FF): deixamos o
# TimeQuest analisar os caminhos inter-clock como sincronos. Como o dado fonte
# fica estavel por 34 ciclos do clock rapido (o operando/St vale 1 CLK_SYS = 34
# CLK_MUL; o Produto se mantem apos Done), declaramos as transferencias como
# MULTICICLO (34:1), evitando Fmax falsamente baixa por analise single-cycle.
# ATENCAO: o multicycle deve casar com o divide_by da PLL (clk0_divide_by=34).
# Ele NAO valida a latencia funcional do MUL (34 estados cabem no periodo de
# CLK_SYS) -> isso e verificado APENAS na simulacao gate-level, nao pelo STA.
#   slow->fast (CLK_SYS -> CLK_MUL): multicycle referido a borda de captura (-end)
set_multicycle_path -setup -end 34 \
    -from [get_clocks {*|altpll_component|*clk[0]}] \
    -to   [get_clocks {*|altpll_component|*clk[1]}]
set_multicycle_path -hold  -end 33 \
    -from [get_clocks {*|altpll_component|*clk[0]}] \
    -to   [get_clocks {*|altpll_component|*clk[1]}]
#   fast->slow (CLK_MUL -> CLK_SYS): multicycle referido a borda de lancamento (-start)
set_multicycle_path -setup -start 34 \
    -from [get_clocks {*|altpll_component|*clk[1]}] \
    -to   [get_clocks {*|altpll_component|*clk[0]}]
set_multicycle_path -hold  -start 33 \
    -from [get_clocks {*|altpll_component|*clk[1]}] \
    -to   [get_clocks {*|altpll_component|*clk[0]}]

# barramentos externos / reset assincrono sem restricao critica
set_false_path -from [get_ports {rst}]
