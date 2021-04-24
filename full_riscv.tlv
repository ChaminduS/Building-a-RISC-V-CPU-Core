\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/risc-v_shell.tlv
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/1d1023ccf8e7b0a8cf8e8fc4f0a823ebb61008e3/risc-v_defs.tlv'])
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])



  m4_test_prog()

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */
\TLV
   
   $reset = *reset;
   
   // Code for the incrementation of the program counter
   $pc[31:0] = >>1$next_pc;
   $next_pc[31:0] = $reset ? 32'b0 : 
                    $taken_br ? $br_tgt_pc :
                    ($pc[31:0] + 32'd4);
   
   // Macro initiation for instruction retrieval
   `READONLY_MEM($pc, $$instr[31:0]);
   
   // Instruction classification
   $is_u_instr = $instr[6:2] ==? 5'b0x101;
   $is_i_instr = $instr[6:2] ==? 5'b0000x || $instr[6:2] ==? 5'b001x0 || $instr[6:2] == 5'b11001;
   $is_r_instr = $instr[6:2] ==? 5'b011x0 || $instr[6:2] == 5'b01011 || $instr[6:2] == 5'b10100;
   $is_s_instr = $instr[6:2] ==? 5'b0100x;
   $is_b_instr = $instr[6:2] == 5'b11000;
   $is_j_instr = $instr[6:2] == 5'b11011;
   
   // Assigning load instructions using only the opcode
   $is_load = ($opcode ==? 7'b0x00011); 
      
   // Extracting fields from the instructions
   $rs2[4:0] = $instr[24:20];
   $funct7[6:0] = $instr[31:25];
   $rs1[4:0] = $instr[19:15];
   $funct3[2:0] = $instr[14:12];
   $rd[4:0] = $instr[11:7];
   $opcode[6:0] = $instr[6:0];
   
   // Assigning boolean values for the validity of these fields
   $rd_valid = ~($is_s_instr || $is_b_instr || $instr[11:7] == 5'b0);
   $imm_valid = ~$is_r_instr;
   $rs1_valid = ~($is_u_instr || $is_j_instr);
   $rs2_valid = ($is_r_instr || $is_s_instr || $is_b_instr);
   
   `BOGUS_USE($rd $rd_valid $rs1 $rs1_valid $rs2 $rs2_valid $funct3 $funct7 $imm $imm_valid);
   
   // Extracting the immediate field from the instruction
   $imm[31:0] = $is_i_instr ? {{21{$instr[31]}}, $instr[30:20]} :
                $is_s_instr ? {{21{$instr[31]}}, $instr[30:25], $instr[11:8], $instr[7]} :
                $is_b_instr ? {{19{$instr[31]}}, {2{$instr[7]}}, $instr[30:25],$instr[11:8], 1'b0} :
                $is_u_instr ? {{2{$instr[31]}}, $instr[30:12], 11'b0} :
                $is_j_instr ? {{11{$instr[31]}}, $instr[19:12], {2{$instr[20]}}, $instr[30:21], 1'b0} :
                32'b0 ;
   
   // Decoding the Instruction
   $dec_bits[10:0] = {$funct7[5], $funct3, $opcode};
   
   $is_beq = $dec_bits ==? 11'bx0001100011;
   $is_bne = $dec_bits ==? 11'bx0011100011;
   $is_blt = $dec_bits ==? 11'bx1001100011;
   $is_bge = $dec_bits ==? 11'bx1011100011;
   $is_bltu = $dec_bits ==? 11'bx1101100011;
   $is_bgeu = $dec_bits ==? 11'bx1111100011;
   $is_addi = $dec_bits ==? 11'bx0000010011;
   $is_add = $dec_bits ==? 11'b00000110011;
   $is_slti = $dec_bits ==? 11'bx0100010011;
   $is_sltiu = $dec_bits ==? 11'bx0110010011;
   $is_xori = $dec_bits ==? 11'bx1000010011;
   $is_ori = $dec_bits ==? 11'bx1100010011;
   $is_andi = $dec_bits ==? 11'bx1110010011;
   $is_slli = $dec_bits ==? 11'b00010010011;
   $is_srli = $dec_bits ==? 11'b01010010011;
   $is_srai = $dec_bits ==? 11'b11010010011;
   $is_sub = $dec_bits ==? 11'b10000110011;
   $is_sll = $dec_bits ==? 11'b00010110011;
   $is_slt = $dec_bits ==? 11'b00100110011;
   $is_sltu = $dec_bits ==? 11'b00110110011;
   $is_xor = $dec_bits ==? 11'b01000110011;
   $is_srl = $dec_bits ==? 11'b01010110011;
   $is_sra = $dec_bits ==? 11'b11010110011;
   $is_or = $dec_bits ==? 11'b01100110011;
   $is_and = $dec_bits ==? 11'b01110110011;
   
   `BOGUS_USE($is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_addi $is_add);
   
   // Arithmetic Logic Unit Code
   $result[31:0] = $is_addi ? $src1_value + $imm:
                   $is_add ? $src1_value[31:0] + $src2_value[31:0]:
                   32'b0;
   
   // Coding the Branching Instruction MUX
   $taken_br = $is_beq ? ($src1_value == $src2_value ? 1'b1 : 1'b0) :
               $is_bne ? ($src1_value != $src2_value ? 1'b1 : 1'b0) :
               $is_blt ? (($src1_value < $src2_value) ^ ($src1_value[31] != $src2_value[31]) ? 1'b1 : 1'b0) :
               $is_bge ? (($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31]) ? 1'b1 : 1'b0) :
               $is_bltu ? ($src1_value < $src2_value ? 1'b1 : 1'b0) :
               $is_bgeu ? ($src1_value >= $src2_value ? 1'b1 : 1'b0) :
               1'b0 ;
   
   // Coding the next instruction location for branching
   $br_tgt_pc[31:0] = $pc[31:0] + $imm ; 
   
   // Assert these to end simulation (before Makerchip cycle limit).
   m4+tb()
   *failed = *cyc_cnt > M4_MAX_CYC;
   
   m4+rf(32, 32, $reset, $rd_valid, $rd[4:0], $result[31:0], $rs1_valid, $rs1, $src1_value, $rs2_valid, $rs2, $src2_value)
   //m4+dmem(32, 32, $reset, $addr[4:0], $wr_en, $wr_data[31:0], $rd_en, $rd_data)
   m4+cpu_viz()
\SV
   endmodule