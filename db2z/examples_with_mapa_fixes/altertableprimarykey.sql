SET CURRENT SQLID = ORAE01;
SET SCHEMA ORAE01;
CREATE TABLESPACE ORATS123
    IN ORADB01
    USING STOGROUP SGDB0U
    PRIQTY -1
    SECQTY -1
    ERASE  NO
    SEGSIZE 32
    TRACKMOD NO
    LOCKMAX 0
    LOCKSIZE ANY
    BUFFERPOOL BP1
    CLOSE YES
    FREEPAGE 0
    PCTFREE 10
    MAXPARTITIONS 1;

-- geen LIKE omdat de NOT NULL VERSION in BETALINGSVERPLICHTING in de update van de AUDITING tabel niet wordt meegenomen
CREATE TABLE MSID_BETALINGSVERPLICHTING_AUD (
    ID                         BIGINT NOT NULL,
    HEFFINGSKENMERK            VARCHAR(26) NOT NULL,
    BETALINGSREFERENTIE_INNEN  VARCHAR(26) NOT NULL,
    BELASTINGJAAR              BIGINT NOT NULL,
    BETALINGSVERPLICHTINGSOORT VARCHAR(15) NOT NULl,
    VERSIEVOLGNUMMER           BIGINT NOT NULL,
    VASTSTELLINGSMOMENT        TIMESTAMP NOT NULL,
    TOTAALBEDRAG               BIGINT,
    UITERSTE_BETAALDATUM       DATE,
    VASTSTELLINGSTATUS         VARCHAR(12),
    BTW_ID_BELASTINGSCHULDIGE  VARCHAR(255) NOT NULL,
    REV                        INT NOT NULL DEFAULT,
    REVTYPE                    SMALLINT
) IN ORADB01.ORATS123
    DATA CAPTURE CHANGES;

CREATE UNIQUE INDEX X01MSID_BETALINGSVERPLICHTING_AUD
    ON MSID_BETALINGSVERPLICHTING_AUD (ID, REV)
    USING STOGROUP SGDB0U
          PRIQTY -1
          SECQTY -1
          ERASE  NO
    CLUSTER
    BUFFERPOOL BP2
    CLOSE YES
    FREEPAGE 0
    PCTFREE  10;

ALTER TABLE MSID_BETALINGSVERPLICHTING_AUD PRIMARY KEY (ID, REV);

COMMIT;
