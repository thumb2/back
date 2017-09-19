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

: welcome ." It's Mickey Board. I'm BACK, initiated in&by Thumb2." ;
: test_ascii ascii A emit ;
: loop begin  test_ascii welcome loop_exit again ;
