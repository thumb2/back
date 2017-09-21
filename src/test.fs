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

: emit begin report while loop_exit repeat ;
: output begin 1+ dup c@ ascii " = not while dup c@ emit repeat drop ;
: skip-string begin 1+ dup c@ ascii " = until 1+ inp ! ;
: ." immediate state if inp @ output 1+ inp ! else compile lit inp @ , compile output inp @ skip-string then ;

: does> here latest @ 12 + ! 0xb500 h, compile lit latest @ 16 + , ;

: var immediate create 0 , does> compile exit ;


: welcome ." It's Mickey Board. I'm BACK, initiated in&by Thumb2." ;
: test_ascii ascii A emit ;
var var_test 
: loop begin  0x38 var_test ! var_test @  emit loop_exit again ;


