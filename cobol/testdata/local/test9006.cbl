       ID Division.
       >>DEFINE X
       >>DEFINE Y B'1'
       >>DEFINE Z 7
       >>DEFINE X X'BADF00D1'
       >>DEFINE Y 'BADF00D1'
       >>DEFINE Z Z + 1
       >>DEFINE X PARAMETER
       >>DEFINE Z OFF
       >>DEFINE Y AS B'1'
       >>DEFINE Z AS 7
       >>DEFINE X AS X'BADF00D1'
       >>DEFINE Y AS 'BADF00D1'
       >>DEFINE Z AS Z + 1
       >>DEFINE X AS PARAMETER
       >>DEFINE Z AS OFF
       >>DEFINE X OVERRIDE
       >>DEFINE Y B'1' OVERRIDE
       >>DEFINE Z 7 OVERRIDE
       >>DEFINE X X'BADF00D1' OVERRIDE
       >>DEFINE Y 'BADF00D1' OVERRIDE
       >>DEFINE Z Z + 1 OVERRIDE
       >>DEFINE X PARAMETER OVERRIDE
       >>DEFINE Z OFF OVERRIDE
       >>DEFINE Y AS B'1' OVERRIDE
       >>DEFINE Z AS 7 OVERRIDE
       >>DEFINE X AS X'BADF00D1' OVERRIDE
       >>DEFINE Y AS 'BADF00D1' OVERRIDE
       >>DEFINE Z AS Z + 1 OVERRIDE
       >>DEFINE X AS PARAMETER OVERRIDE
       >>DEFINE Z AS OFF OVERRIDE
       Program-ID. test9006.
       Procedure Division.
           GOBACK.
