# =============================================================================
# risc.sdc - Restricoes de timing (TimeQuest).
#
# CLK e o clock de referencia (= CLK_MUL, 100 MHz no modelo). O modelo de PLL
# repassa CLK_MUL = CLK e gera CLK_SYS = CLK/40 por um divisor.
#
# Definimos o clock de entrada e o clock gerado (CLK_SYS) para que o TimeQuest
# analise os dois dominios. A Fmax reportada por dominio (caminho critico
# FF->FF) responde aos itens (c) e (d) do roteiro.
# =============================================================================
create_clock -name CLK -period 10.000 [get_ports CLK]

# CLK_SYS = CLK / 40 (saida do divisor dentro do modelo de PLL)
create_generated_clock -name CLK_SYS -source [get_ports CLK] -divide_by 40 \
    [get_pins -nocase -compatibility_mode {*pll*c0*|q}]

derive_clock_uncertainty

# entradas/saidas externas sem restricao critica (barramentos externos)
set_false_path -from [get_ports {rst}]
