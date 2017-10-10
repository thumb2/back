: >mark here 0 , ;
: >resolve here swap ! ;
: <mark here ;
: <resolve , ;

: if immediate compile ?branch >mark ;
: else immediate compile branch >mark swap >resolve ;
: then immediate >resolve ;
: begin immediate <mark ;
: until immediate compile ?branch <resolve ;
: again immediate compile branch <resolve ;
: while immediate compile ?branch >mark ;
: repeat immediate swap compile branch <resolve >resolve ;

: case immediate 0 ;
: endcase immediate compile drop begin ?dup while >resolve repeat ;
: of immediate compile over compile = compile ?branch >mark compile drop ;
: endof immediate compile branch >mark swap >resolve ;


: emit begin report while loop_exit repeat ;
: output begin 1+ dup c@ ascii " = not while dup c@ emit repeat drop ;
: skip-string begin 1+ dup c@ ascii " = until 1+ inp ! ;
: ." immediate state if inp @ output 1+ inp ! else compile lit inp @ , compile output inp @ skip-string then ;

: does> here latest @ 12 + ! 0xb500 h, compile lit latest @ 16 + , ;

: variable immediate create 0 , does> compile exit ;
: array immediate create allot  does> compile + compile exit ;

: welcome ." It's Mickey Board. I'm BACK, initiated in&by Thumb2." ;
: test_ascii ascii A emit ;
variable var_test
8 array array_test

: case_test
    kf_pwp c@ case
        0 of ." it's 0 " endof
        4 of ." it's 4 " endof
        ." it's not 3 or 4 "
    endcase
;

: input_buffer_get_char
    begin kf_pwp c@ kf_prp c@ <> while
            kf kf_prp c@ + c@ emit
            kf_prp dup c@ 1+ dup 16 = if 16 - then swap c!
    repeat
;

            
: loop begin  input_buffer_get_char  loop_exit again ;


