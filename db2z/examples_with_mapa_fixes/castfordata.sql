SELECT CAST(MEL.MEL_ID as INTEGER),
       AFS.AFNEMER,
       STR.BERICHTSTROOM,
       CAST(YEAR(mel.UITBETALINGSDATUM) as SMALLINT),
       current_timestamp,
       CAST(SST.BERICHTSOORT as VARCHAR(20)),
       CASE
           WHEN BER.RSIN_BRON IS NOT null THEN CAST(BER.RSIN_BRON as DECIMAL(9))
           --ELSE CAST(SUBSTRING(BER.LHNR_BRON, 1, 8, OCTETS) as DECIMAL(9)) END AS RSIN,
           ELSE BER.LHNR_BRON END AS RSIN,
       CAST(SUBSTRING(BER.BRON_NAAM, 1, 70, OCTETS) AS CHAR(70) FOR MIXED DATA),
       BER.KWALIFICATIE,
       MEL.KWALIFICATIE,
       cast(NULL as CHAR(20)),
       cast(NULL as CHAR(34)),
       cast(NULL as CHAR(50)),
       cast(NULL as CHAR(1)),
       CASE
           WHEN MEL.ONTVANGER_BSN_VASTGESTELD IS NOT null THEN CAST(MEL.ONTVANGER_BSN_VASTGESTELD as INTEGER)
           ELSE CAST(MEL.ONTVANGER_BSN as INTEGER)
           END                                                                      AS BSN,
       cast(NULL as CHAR(1)),
       cast(NULL as VARCHAR(34)),
       CAST(mel.BEDRAG as DECIMAL(13)),
       cast(NULL as CHAR(3)),
       cast(NULL as DECIMAL(13)),
       cast(NULL as CHAR(1)),
       cast(NULL as int),
       cast(NULL as CHAR(2)),
       cast(NULL as CHAR(2)),
       cast(NULL as SMALLINT)
FROM MELDING MEL
         LEFT JOIN BERICHT BER on MEL.BER_ID = BER.BER_ID
         LEFT JOIN LEVERING LEV on BER.LEV_ID = LEV.LEV_ID
         LEFT JOIN MQBERICHT MQB on LEV.MQB_ID = MQB.MQB_ID
         LEFT JOIN SUBSTROOM SST on MQB.SST_ID = SST.SST_ID
         LEFT JOIN STROOM STR on SST.STR_ID = STR.STR_ID
         LEFT JOIN APPLICATIETAAKBESTURING ATB ON STR.STR_ID = ATB.STR_ID AND ATB.TAAKNUMMER = 'AT-1500'
         LEFT JOIN AFNEMERSTURING AFS on ATB.ATB_ID = AFS.ATB_ID
WHERE AFS.AFNEMER = 'BNA'
  AND MEL.STATUS_BNA in (SELECT STATUS FROM AFNEMERSTURING WHERE AFNEMER = 'BNA');
