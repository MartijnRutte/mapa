// AFTER NAME=JOB001
// AFTER NAME=(JOB001,JOB002)
// AFTER NAME=(JOB001,
// JOB002)
// AFTER NAME=(JOB001)
// AFTER NAME=JOB001,WHEN=(RC=4)
// AFTER NAME=(JOB001,JOB002),WHEN=(RC=4)
// AFTER NAME=(JOB001,
// JOB002),WHEN=(RC=4)
// AFTER NAME=(JOB001),WHEN=(RC=4)
// AFTER NAME=JOB001,WHEN=(RC EQ 4 OR RC EQ 8)
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | ABEND)
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN))
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)),
//  ACTION=SATISFY
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)),
//  ACTION=FLUSH
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)),
//  ACTION=FAIL
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)),
//  OTHERWISE=SATISFY
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)),
//  OTHERWISE=FLUSH
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)),
//  OTHERWISE=FAIL
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)),
//  ACTION=SATISFY,OTHERWISE=FAIL
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)),
//  ACTION=FLUSH,OTHERWISE=SATISFY
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)),
//  ACTION=FAIL,OTHERWISE=FLUSH
// AFTER NAME=JOB001 comment
// AFTER NAME=(JOB001,JOB002) comment
// AFTER NAME=(JOB001,
// JOB002) comment
// AFTER NAME=(JOB001) comment
// AFTER NAME=JOB001,WHEN=(RC=4) comment
// AFTER NAME=(JOB001,JOB002),WHEN=(RC=4) comment
// AFTER NAME=(JOB001,
// JOB002),WHEN=(RC=4) comment
// AFTER NAME=(JOB001),WHEN=(RC=4) comment
// AFTER NAME=JOB001,WHEN=(RC EQ 4 OR RC EQ 8) comment
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | ABEND) comment
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)) comment
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)), comment
//  ACTION=SATISFY comment
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)), comment
//  ACTION=FLUSH comment
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)), comment
//  ACTION=FAIL comment
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)), comment
//  OTHERWISE=SATISFY comment
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)), comment
//  OTHERWISE=FLUSH comment
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)), comment
//  OTHERWISE=FAIL comment
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)), comment
//  ACTION=SATISFY,OTHERWISE=FAIL comment
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)), comment
//  ACTION=FLUSH,OTHERWISE=SATISFY comment
// AFTER NAME=JOB001,WHEN=((RC EQ 4 OR RC EQ 8) | 
//  (ABENDCC = U4038 | !RUN)), comment
//  ACTION=FAIL,OTHERWISE=FLUSH comment
//AFTER JOB