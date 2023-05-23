SET CURRENT SQLID = DBAE01;
SET SCHEMA DBAE01;

--#SET TERMINATOR `                                             
  CREATE PROCEDURE DBADSP02                                          
    (OUT O_FOUTBOODSCHAP CHAR( 50) FOR SBCS DATA CCSID EBCDIC)       
   VERSION VERSION1                     
   LANGUAGE SQL                         
   NOT DETERMINISTIC                    
   MODIFIES SQL DATA                    
   CALLED ON NULL INPUT                 
   DYNAMIC RESULT SETS 0                
   DISABLE DEBUG MODE                   
   PARAMETER CCSID EBCDIC               
   QUALIFIER DBAE01                     
   PACKAGE OWNER DBAE                 
   ASUTIME LIMIT 100000                 
   COMMIT ON RETURN NO                  
   INHERIT SPECIAL REGISTERS            
   NODEFER PREPARE                      
   CURRENT DATA NO                      
   DEGREE 1                             
   DYNAMICRULES RUN                     
   WITHOUT EXPLAIN                      
   WITHOUT IMMEDIATE WRITE              
   ISOLATION LEVEL UR                   
   WITHOUT KEEP DYNAMIC                 
   OPTHINT ''                           
   SQL PATH "DEFAULT"                   
   RELEASE AT COMMIT                                                  
   REOPT NONE                                                         
   VALIDATE BIND                                                      
   ROUNDING DEC_ROUND_HALF_EVEN                                       
   DECIMAL(31)                                                        
   A:                                                                 
   BEGIN                                                              
     DECLARE SQLSTATE                      CHAR(5)   DEFAULT '00000'; 
     DECLARE SQLCODE                       INTEGER   DEFAULT 0 ;      
     DECLARE H_AANTAL                      INTEGER   DEFAULT 0 ;      
     DECLARE NOT_FOUND                     CHAR( 1)  DEFAULT 'N' ;    
     DECLARE SQL_EXCEPT                    CHAR( 1)  DEFAULT 'N' ;    
     DECLARE ERRORHULP                     CHAR( 50) DEFAULT '' ;     
     DECLARE ERRORLABEL                    CHAR( 70) DEFAULT '' ;     
                                                                      
     DECLARE H_ID                          INTEGER   DEFAULT 0 ;      
     DECLARE S_ID                          INTEGER   DEFAULT 0 ;  
     DECLARE H_GEADRESSEERDE_ID            INTEGER   DEFAULT 0 ; 	 
     DECLARE H_GEADRESSEERDETYPE           CHAR(  2) DEFAULT '' ;     
     DECLARE H_IDENTIFICATIE               CHAR( 30) DEFAULT '' ;     
     DECLARE S_IDENTIFICATIE               CHAR( 30) DEFAULT '' ;     
     DECLARE H_OMSCHRIJVING                CHAR( 50) DEFAULT '' ;     
     DECLARE S_OMSCHRIJVING                CHAR( 50) DEFAULT '' ;     
     DECLARE O_OMSCHRIJVING                CHAR( 48) DEFAULT '' ;     
     DECLARE H_USERID                      CHAR(10) DEFAULT 'DBADSP';
     DECLARE H_GROEP                       CHAR( 30) DEFAULT '' ;  
     DECLARE H_VOORKEURSADRES              CHAR(  1) DEFAULT '' ;  
     DECLARE H_LAE_ID 			           INTEGER   DEFAULT 0 ;   
     DECLARE S_LAE_ID  			           INTEGER   DEFAULT 0 ;   
     DECLARE H_LOGISTIEKEAFSPRAAKEXTERN_ID INTEGER   DEFAULT 0 ;   
     DECLARE S_LOGISTIEKEAFSPRAAKEXTERN_ID INTEGER   DEFAULT 0 ;   
                                                                   
     DECLARE H_BERICHTSTROOM               CHAR( 30) DEFAULT '' ;  
     DECLARE H_BERICHTTYPE                 CHAR( 30) DEFAULT '' ;  
     DECLARE H_KANAAL                      CHAR( 10) DEFAULT '' ;  
     DECLARE H_BERICHTFORMAAT              CHAR( 10) DEFAULT '' ;  
     DECLARE H_CSIMSGTYPE                  CHAR( 10) DEFAULT '' ;  
     DECLARE H_SOORTADRES                  CHAR( 30) DEFAULT '' ;  
     DECLARE H_BEWERKING                   CHAR( 30) DEFAULT '' ;  
                                                                   
     DECLARE CONTINUE HANDLER FOR SQLEXCEPTION                     
                                                                   
     BEGIN                                                         
       SET O_FOUTBOODSCHAP =                                       
         CONCAT('DBADSP02 VERWERKING FOUT: SQLSTATE ', SQLSTATE);  
       SET O_FOUTBOODSCHAP = RTRIM(O_FOUTBOODSCHAP);               
     END ;                                                         
                                                              
--    START FOR LOOP MET SELECTIE VAN TE VERWERKEN RECORDS    
                                                              
      BEGIN                                                   
        FOR V1 AS                                             
            C1 CURSOR FOR     

         SELECT                                               
           LAE.ID AS LAE_ID    
			, LAE.GEADRESSEERDE_ID
			, LAE.BERICHTTYPE
			, LAE.KANAAL
			, LAE.CSIMSGTYPE
			, LAE.SOORTADRES
			, LAE.BEWERKING                                                            
         FROM LOGISTIEKEAFSPRAAKEXTERN AS LAE                           
         WHERE (LAE.BERICHTSTROOM = 'AGS')                                                  
         ORDER BY LAE.ID                                              
                                                                        
          DO                                                            
            SET H_ID                                                    
              = LAE_ID;                                                         
            SET H_GEADRESSEERDE_ID                                      
              = GEADRESSEERDE_ID;                                                  
            SET H_BERICHTTYPE                                                   
              = BERICHTTYPE;                                                  
            SET H_KANAAL                                    
              = KANAAL;                                      
            SET H_CSIMSGTYPE                                         
              = CSIMSGTYPE;                                          
            SET H_SOORTADRES                                         
              = SOORTADRES;                                                                                           
            SET H_BEWERKING                                       
              = BEWERKING;                                                                                         
                                                                        
--   ER MAG MAAR 1 LOGISTIEKEAFSPRAAKEXTERN PER ID WORDEN AANGEMAAKT 
                                                                   
            IF H_ID <> S_ID THEN                                                                                                                                                                                   
                                                      
--   BEWAAR IDENTIFICATIE VAN LOGISTIEKEAFSPRAAKEXTERN           
                                                      
               SET S_ID                               
                 = H_ID;                                             
                                                                                             
            END IF;        

--   MAAK NIEUWE LOGISTIEKEAFSPRAAKEXTERN AAN                        
                                                   
            INSERT INTO LOGISTIEKEAFSPRAAKEXTERN   
            (ID                                    
            , VERSION                              
            , GEADRESSEERDE_ID                     
            , BERICHTSTROOM                        
            , BERICHTTYPE                          
            , KANAAL                               
            , BERICHTFORMAAT                       
            , BEGINDATUMTIJD                       
            , EINDDATUMTIJD                        
            , USERID                               
            , DATUMTIJD                            
            , CSIMSGTYPE                           
            , SOORTADRES                           
            , BEWERKING)                           
            VALUES                                 
            (NEXTVAL FOR SEQBERICHT                
            , 1                                    
            , H_GEADRESSEERDE_ID                   
            , 'DMS'                      
            , H_BERICHTTYPE                        
            , H_KANAAL                             
            , 'XML'                        
            , CURRENT TIMESTAMP                       
            , '9999-12-31 23:59:00.000000'            
            , 'DMSUSER'                                
            , CURRENT TIMESTAMP                       
            , H_CSIMSGTYPE                            
            , H_SOORTADRES                            
            , H_BEWERKING);                           
                                                      
--   BEWAAR NIEUWE ID VAN LOGISTIEKEAFSPRAAKEXTERN    
                                                      
            SET S_LOGISTIEKEAFSPRAAKEXTERN_ID         
              = SEQBERICHT.CURRVAL;                   
                                                      
--   MAAK NIEUWE LOGISTIEKADRESEXTERN AAN (IS KOPIE)      

			INSERT INTO LOGISTIEKADRESEXTERN (ID, VERSION, LOGISTIEKEAFSPRAAKEXTERN_ID, ELEKTRONISCHADRES, USERID, DATUMTIJD) 
				SELECT NEXTVAL FOR SEQBERICHT, 1, S_LOGISTIEKEAFSPRAAKEXTERN_ID, LAD.ELEKTRONISCHADRES, 'DMSUSER', CURRENT TIMESTAMP 
				FROM LOGISTIEKADRESEXTERN LAD 
				WHERE (LAD.LOGISTIEKEAFSPRAAKEXTERN_ID = H_ID);                                                                         
			                   
            SET H_AANTAL = H_AANTAL + 1;              
                                                        
        END FOR;                                        
      END;                                              
                                                        
      BEGIN                                             
        SET O_FOUTBOODSCHAP =                           
          CONCAT('VERWERKING OK: AANTAL = ',H_AANTAL);  
        SET O_FOUTBOODSCHAP = RTRIM(O_FOUTBOODSCHAP);   
      END ;                                             
                                                        
    END A `

--#SET TERMINATOR ; 

GRANT EXECUTE ON PROCEDURE DBADSP02 TO DBAE;
GRANT EXECUTE ON PROCEDURE DBADSP02 TO $EDBA60;
 
GRANT SELECT ON LOGISTIEKADRESEXTERN TO $EDBA00; 
GRANT SELECT ON LOGISTIEKEAFSPRAAKEXTERN TO $EDBA00;  
                                                            
GRANT SELECT ON LOGISTIEKADRESEXTERN TO EDBAREAD;
GRANT SELECT ON LOGISTIEKEAFSPRAAKEXTERN TO EDBAREAD;
                                                            
GRANT SELECT, INSERT, UPDATE, DELETE ON LOGISTIEKADRESEXTERN TO $EDBA60; 
GRANT SELECT, INSERT, UPDATE, DELETE ON LOGISTIEKEAFSPRAAKEXTERN TO $EDBA60; 

COMMIT;
                                                
