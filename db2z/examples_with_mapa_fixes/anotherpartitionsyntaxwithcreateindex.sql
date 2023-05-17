CREATE UNIQUE INDEX PK_PMML_SCORE_GEG
    ON PMML_SCORE_GEG
    (PSG_VERSIENR                             ASC,
     PSG_PROCES                               ASC,
     PSG_PROJECTNAAM                          ASC,
     PSG_AANROEPMOMENT                        ASC)
  PARTITIONED
  USING STOGROUP SGDB0U
     PRIQTY        -1
     SECQTY        -1
     FREEPAGE 0 PCTFREE 10
     GBPCACHE CHANGED
     CLUSTER
     COMPRESS NO
     (PARTITION  1,
      PARTITION  2,
      PARTITION  3,
      PARTITION  4,
      PARTITION  5,
      PARTITION  6)
     BUFFERPOOL BP2
     CLOSE YES
     COPY NO
     DEFER NO
     DEFINE YES;
