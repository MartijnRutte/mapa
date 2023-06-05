SET CURRENT SQLID = IOAE01;
SET SCHEMA IOAE01;
--
-- IAB-17398: Toevoegen LifeCycleStatus aan Aanmaken Journaalposten
--
-- PROCEDURE AANMAKEN_JOURNAALPOSTEN
--
--#SET TERMINATOR @
CREATE PROCEDURE aanmaken_journaalposten
    ( p_debug                                     VARCHAR(1) IN
     ,p_bjb_id                                        BIGINT IN
     ,p_startcreatiemoment                         TIMESTAMP IN
     ,p_startcreatiemoment_laatste_batchjob        TIMESTAMP IN
     ,p_boekdatum                                       DATE IN
     ,p_alles_verwerkt                             SMALLINT OUT
    )
    LANGUAGE SQL
    MODIFIES SQL DATA
    ASUTIME LIMIT 500000
    PACKAGE OWNER IOAE
    ALLOW DEBUG MODE
    WLM ENVIRONMENT FOR DEBUG MODE EIOASP00
BEGIN
    DECLARE l_aantal_jpo                      BIGINT DEFAULT 0;
    DECLARE l_aantal_jpr                      BIGINT DEFAULT 0;
    DECLARE l_aantal_jpl                      BIGINT DEFAULT 0;
    DECLARE l_datasetid                       BIGINT DEFAULT 0;
    DECLARE l_ffid                                      BIGINT;
    DECLARE l_save_sqlcode                   INTEGER DEFAULT 0;
    DECLARE l_save_sqlstate                CHAR(5) DEFAULT ' ';
    DECLARE l_save_errmsg            VARCHAR(260) DEFAULT  ' ';
    DECLARE l_stmt                               VARCHAR(4000);

    -- init aantal variabelen
    DECLARE l_batchjobnaam     VARCHAR(50) DEFAULT
                                     'AANMAKEN_JOURNAALPOSTEN';

    BEGIN

        -- De aan te maken journaalposten incl extra gegevens worden
        -- eerst vastgelegd in een tijdelijke tabel zodat deze
        -- informatie in de rest van de procedure beschikbaar is
        DECLARE GLOBAL TEMPORARY TABLE journaalpostselectie
          ( journaalpost_id                    BIGINT NOT NULL
           ,boekdatum                            DATE NOT NULL
           ,bronadministratie                 INTEGER NOT NULL
           ,financieelfeitsoort          VARCHAR(255) NOT NULL
           ,ffaanmaakdatum                       DATE NOT NULL
           ,bedrag                     DECIMAL(19, 2) NOT NULL
           ,journaalpostparameter_id           BIGINT NOT NULL
           ,financieelfeit_id                  BIGINT NOT NULL
           ,componenttype                         VARCHAR(255)
           ,belastingjaar                              INTEGER
          );

        -- bepaal dataset id
        SET l_datasetid = NEXT VALUE FOR seq_jpo_datasetid;

        -- Lock tables
        LOCK TABLE JOURNAALPOST IN EXCLUSIVE MODE;
        LOCK TABLE JOURNAALPOSTREGEL IN EXCLUSIVE MODE;
        LOCK TABLE JOURNAALPOSTLIFECYCLESTATUS IN EXCLUSIVE MODE;

        -- bepaal journaalposten en sla op in tijdelijke tabel
        -- journaalpostselectie
        INSERT INTO session.journaalpostselectie
              ( journaalpost_id
               ,boekdatum
               ,bronadministratie
               ,financieelfeitsoort
               ,ffaanmaakdatum
               ,bedrag
               ,journaalpostparameter_id
               ,financieelfeit_id
               ,componenttype
               ,belastingjaar
              )
              SELECT NEXT VALUE FOR
                     seq_pk_jpo
                    ,max(p_boekdatum, ffe.boekdatum) boekdatum
                    ,jpp.bronadministratie
                    ,jpp.financieelfeitsoort
                    ,DATE(ffe.creatiemoment) ffaanmaakdatum
                    ,ffe.bedrag
                    ,jpp.id journaalpostparameter_id
                    ,ffe.id financieelfeit_id
                    ,ffe.componenttype
                    ,ffe.belastingjaar
                FROM (SELECT * FROM financieelfeit ffe2
                        WHERE ffe2.creatiemoment <= p_startcreatiemoment
                        AND ffe2.creatiemoment > p_startcreatiemoment_laatste_batchjob
                      UNION
                      SELECT ffe2.* FROM journaalpost jpo
                        JOIN financieelfeit ffe2 ON jpo.financieelfeit_id = ffe2.id
                        WHERE jpo.mutatiemoment <= p_startcreatiemoment
                        AND jpo.mutatiemoment > p_startcreatiemoment_laatste_batchjob
                        AND jpo.huidigelifecyclestatus <> 'GEACTIVEERD'
                     ) ffe
          INNER JOIN journaalpostparameters jpp
                  ON ffe.code = jpp.financieelfeitcode
               WHERE jpp.doeladministratie = ffe.doeladministratie
                 AND jpp.waardebereik =
                    (CASE WHEN ffe.bedrag >= 0
                            THEN 'POSITIEF'
                          ELSE 'NEGATIEF'
                     END
                    )
                 AND (   (jpp.soort = ffe.soortbetalingsverplichting)
                      OR (    jpp.soort IS NULL
                          AND ffe.soortbetalingsverplichting IS NULL
                         )
                     )
                 AND (   (jpp.belastingmiddel = ffe.soortmiddel)
                      OR (    jpp.belastingmiddel IS NULL
                          AND ffe.soortmiddel IS NULL
                         )
                     )
                AND NOT EXISTS (SELECT 1
                                 FROM journaalpost jpo
                                 WHERE jpo.financieelfeit_id = ffe.id
                                 AND jpo.huidigelifecyclestatus = 'GEACTIVEERD'
                               )
                AND jpp.geldigvanaf <= DATE(p_startcreatiemoment)
                AND jpp.geldigtm >= DATE(p_startcreatiemoment)
              FETCH FIRST 10000 ROWS ONLY;

        -- insert journaalposten a.d.h.v. eerder gemaakte selectie
        INSERT INTO journaalpost
        ( id
         ,boekdatum
         ,bronadministratie
         ,financieelfeit_id
         ,financieelfeitsoort
         ,ffaanmaakdatum
         ,datasetid
         ,creatiemoment
         ,mutatiemoment
         ,huidigelifecyclestatus
        )
        SELECT journaalpost_id
              ,boekdatum
              ,bronadministratie
              ,financieelfeit_id
              ,financieelfeitsoort
              ,ffaanmaakdatum
              ,l_datasetid
              ,current timestamp
              ,current timestamp
              ,'GEACTIVEERD'
          FROM session.journaalpostselectie jps;
           GET DIAGNOSTICS l_aantal_jpo = ROW_COUNT;

        -- Wanneer het aantal verwerkte financiele feiten kleiner dan
        -- 10000 dan zal de deling een getal minder dan 1 opleveren.
        -- Bij een getal minder dan 10000 betekent dat alle financiele
        -- feiten verwerkt zijn.
        SET p_alles_verwerkt =
            CASE
              WHEN (l_aantal_jpo/10000) < 1
                THEN 1
               ELSE 0
            END;

        -- geen records meer te verwerken
        IF p_alles_verwerkt = 1
        THEN
            CALL ins_batch_job_log_info
            ( p_debug
             ,p_bjb_id
             ,'Laastste run; alles verwerkt is 1'
            );
        END IF;

        -- insert log regel
        CALL ins_batch_job_log_info
        (  p_debug
          ,p_bjb_id
          ,'aantal inserted journaalposten : '
         ||l_aantal_jpo
         ||' voor dataset '
         ||l_datasetid
        );

        -- insert journaalpostregels
        INSERT INTO journaalpostregel
        ( id
         ,bedrag
         ,belastingjaar
         ,component
         ,debetcreditindicator
         ,grootboekrekeningnummer
         ,productcode
         ,creatiemoment
         ,mutatiemoment
         ,journaalpost_id
        )
        SELECT NEXT VALUE FOR
               seq_pk_jpr
              ,ABS(jps.bedrag)
              ,CASE
                 WHEN jrp.belastingjaarindicatie = 'J'
                   THEN jps.belastingjaar
                 ELSE NULL
               END belastingjaar
              ,CASE WHEN jrp.componentindicatie = 'J'
                 THEN
                   (SELECT jcp.componentcode
                      FROM journaalpostcomponentparameters jcp
                     WHERE jcp.componenttype = jps.componenttype
                       AND jcp.geldigvanaf =
                          (SELECT max(geldigvanaf)
                             FROM journaalpostcomponentparameters jcp1
                            WHERE jcp1.componenttype = jcp.componenttype
                              AND jcp1.geldigvanaf <=
                                  DATE(p_startcreatiemoment)
                          )
                   )
                 ELSE NULL
               END component
              ,jrp.debetcreditindicator
              ,jrp.grootboekrekening
              ,jrp.productcode
              ,current timestamp
              ,current timestamp
              ,jps.journaalpost_id
          FROM session.journaalpostselectie jps
    INNER JOIN journaalpostregelparameters jrp
            ON jps.journaalpostparameter_id =
               jrp.journaalpostparameters_id;
           GET DIAGNOSTICS l_aantal_jpr = ROW_COUNT;

        -- insert log regel
        CALL ins_batch_job_log_info
        (  p_debug
          ,p_bjb_id
          ,'aantal inserted journaalpostregels : '
         ||l_aantal_jpr
         ||' voor dataset '
         ||l_datasetid
        );

        -- insert records in lifecyclestatus tabel journaalpostlifecyclestatus
        INSERT INTO journaalpostlifecyclestatus
        ( id
         ,creatiemoment
         ,mutatiemoment
         ,journaalpost_id
         ,status
        )
        SELECT NEXT VALUE FOR
               seq_pk_jpl
              ,current timestamp
              ,current timestamp
              ,journaalpost_id
              ,'GEACTIVEERD'
          FROM session.journaalpostselectie;
           GET DIAGNOSTICS l_aantal_jpl = ROW_COUNT;

        -- insert log regel
        CALL ins_batch_job_log_info
        (  p_debug
          ,p_bjb_id
          ,'aantal inserted journaalpostlifecyclestatus records : '
         ||l_aantal_jpl
        );

        -- opruimen temp table
        DROP TABLE session.journaalpostselectie;
    END ;
END @

--
-- G R A N T
--
GRANT EXECUTE
ON PROCEDURE AANMAKEN_JOURNAALPOSTEN
TO IOAE, $EIOA60, $EIOA61, $EIOA82
    @

COMMIT @
---------------------------------------------------------------------
--#SET TERMINATOR ;
---------------------------------------------------------------------

