CREATE TABLE JOURNAALPOST
    (ID                                                BIGINT NOT NULL,
     BOEKDATUM                                                    DATE,
     BRONADMINISTRATIE                                    INT NOT NULL,
     FINANCIEELFEITSOORT                         VARCHAR(255) NOT NULL,
     FFAANMAAKDATUM           DATE DEFAULT DATE('1900-01-01') NOT NULL,
     DATASETID                                                  BIGINT,
     AGGREGATIEUITGEVOERD                  SMALLINT DEFAULT 0 NOT NULL,
     CREATIEMOMENT                                  TIMESTAMP NOT NULL,
     MUTATIEMOMENT                                  TIMESTAMP NOT NULL,
     CONSTRAINT  PK_JPO
    PRIMARY KEY (ID)
    )
    IN IOADB01.IOATSJPO
    DATA CAPTURE CHANGES
    CCSID      UNICODE
    ;
