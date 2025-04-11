onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group SYSTEM /top/clk
add wave -noupdate -expand -group SYSTEM /top/rst_n
add wave -noupdate -expand -group {APB INTERFACE} /top/psel
add wave -noupdate -expand -group {APB INTERFACE} /top/paddr
add wave -noupdate -expand -group {APB INTERFACE} /top/pwrite
add wave -noupdate -expand -group {APB INTERFACE} /top/prdata
add wave -noupdate -expand -group {APB INTERFACE} /top/pwdata
add wave -noupdate -expand -group {APB INTERFACE} /top/penable
add wave -noupdate -expand -group {APB INTERFACE} /top/pready
add wave -noupdate -expand -group {APB INTERFACE} /top/pslverr
add wave -noupdate -expand -group {I2C INTERFACE} /top/scl
add wave -noupdate -expand -group {I2C INTERFACE} /top/sda
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {299 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {2838 ns}
