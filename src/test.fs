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

: input_buffer_can_move_left?
    input_buffer_cursor dup @    
    input_buffer_begin @
    <
;

: input_buffer_can_move_right?
    input_buffer_cursor dup @    
    input_buffer_end @
    >
;

: input_buffer_move_left
    input_buffer_can_move_left? if
        input_buffer_cursor dup @ 1- swap !
    then
;

: input_buffer_move_right
    input_buffer_can_move_right? if
        input_buffer_cursor dup @ 1+ swap !
    then
;

: input_buffer_insert
    dup emit
    input_buffer_cursor @
    input_buffer_end dup @ 1+ dup rot !
    begin over over <> while
            dup 1- dup c@ rot c!
    repeat
    drop 
    c!
    input_buffer_cursor dup @ 1+ swap !
;

: input_buffer_raw_delete
    begin over over <> while
            dup 1+ dup c@ rot c!
    repeat
    drop drop
    input_buffer_end dup @ 1- swap !
;
: input_buffer_delete
    input_buffer_end @
    input_buffer_cursor @
    input_buffer_raw_delete
;

: input_buffer_backspace
    input_buffer_can_move_left? if 
        input_buffer_end @
        input_buffer_cursor @ 1- dup rot !
        input_buffer_raw_delete        
    then
;

: input_buffer_enter
    0x0a
    input_buffer_insert    
    0x0d
    input_buffer_insert    
    input_buffer_begin @ 
    inp !
    begin interpret until
    input_buffer_begin @
    dup input_buffer_end !    
    dup input_buffer_cursor !
    0 swap c!
;


: input_buffer_process
    case
        0x0d of input_buffer_enter endof
        0x01 of input_buffer_move_left endof
        0x02 of input_buffer_move_right endof
        0x08 of input_buffer_backspace endof
        0x7F of input_buffer_delete endof        
        dup input_buffer_insert
    endcase
;

: input_buffer_get_char
    begin kf_pwp c@ kf_prp c@ <> while
            kf kf_prp c@ + c@ input_buffer_process
            kf_prp dup c@ 1+ dup 16 = if 16 - then swap c!
    repeat
;

: loop begin input_buffer_get_char  loop_exit again ;

1 2 + 0x30 + emit welcome
