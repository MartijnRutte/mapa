SET CURRENT SQLID = DBAE01;
SET SCHEMA DBAE01;

--#SET TERMINATOR `                                             
  CREATE PROCEDURE DBADSP03                                          
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
   ASUTIME LIMIT 1000000                 
   COMMIT ON RETURN NO                  
   INHERIT SPECIAL REGISTERS            
   NODEFER PREPARE                      
   CURRENT DATA NO                      
   DEGREE 1                             
   DYNAMICRULES RUN                     
   WITH EXPLAIN                      
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
P1: 
   BEGIN                                                              
     DECLARE SQLSTATE                      CHAR(5)   DEFAULT '00000'; 
     DECLARE SQLCODE                       INTEGER   DEFAULT 0 ;      
     DECLARE H_AANTAL                      BIGINT    DEFAULT 0 ;      
     DECLARE NOT_FOUND                     CHAR( 1)  DEFAULT 'N' ;    
     DECLARE SQL_EXCEPT                    CHAR( 1)  DEFAULT 'N' ;    
     DECLARE ERRORHULP                     CHAR( 50) DEFAULT '' ;     
     DECLARE ERRORLABEL                    CHAR( 70) DEFAULT '' ;     
                                                                      
     DECLARE H_ID                          INTEGER   DEFAULT 0 ;      
     DECLARE S_ID                          INTEGER   DEFAULT 0 ;  
     DECLARE H_GEADRESSEERDE_ID            INTEGER   DEFAULT 0 ; 	 
	 DECLARE S_GEADRESSEERDE_ID            INTEGER   DEFAULT 0 ;
     DECLARE H_GEADRESSEERDETYPE           CHAR(  2) DEFAULT '' ;     
     DECLARE H_IDENTIFICATIE               CHAR( 30) DEFAULT '' ;     
     DECLARE S_IDENTIFICATIE               CHAR( 30) DEFAULT '' ;     
     DECLARE H_OMSCHRIJVING                CHAR( 50) DEFAULT '' ;     
     DECLARE S_OMSCHRIJVING                CHAR( 50) DEFAULT '' ;     
     DECLARE O_OMSCHRIJVING                CHAR( 48) DEFAULT '' ;     
     DECLARE H_USERID                      CHAR(10) DEFAULT 'BSNLOOS';
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
	 
	 DECLARE H_GEAD_ID                     INTEGER   DEFAULT 0 ;  
	 DECLARE H_GEAD_EORI                   CHAR( 30) DEFAULT '' ; 

	 DECLARE F_ID							INTEGER;
	 DECLARE F_VERSION						INTEGER;
	 DECLARE F_GEADRESSEERDE_ID				INTEGER;
	 DECLARE F_BERICHTSTROOM				CHAR(30);
	 DECLARE F_BERICHTTYPE					CHAR(30);
	 DECLARE F_KANAAL						CHAR(10);
	 DECLARE F_BERICHTFORMAAT				CHAR(10);
	 DECLARE F_BEGINDATUMTIJD				TIMESTAMP(6);
	 DECLARE F_EINDDATUMTIJD				TIMESTAMP(6);
	 DECLARE F_USERID						CHAR(10);
	 DECLARE F_DATUMTIJD					TIMESTAMP(6);
	 DECLARE F_CSIMSGTYPE					CHAR(10);
	 DECLARE F_SOORTADRES					CHAR(30);
	 DECLARE F_BEWERKING					CHAR(30);
	 
	 DECLARE TELLER INTEGER;
	 DECLARE TELLER_2 INTEGER;
	 DECLARE STOPPEN_BIJ INTEGER;
	 DECLARE STOPPEN_BIJ_2 INTEGER;
	 
	 DECLARE IPARID INTEGER DEFAULT 999 ;  
	 DECLARE GEAD_OK INTEGER DEFAULT 0 ;  
	 
	 DECLARE GLOBAL TEMPORARY TABLE SESSION.TEMP_GEGEVENS(GEAD_ID INT, GEAD_EORI CHAR(30)) NOT LOGGED ON COMMIT DROP TABLE;                                                                                                                         	 
		
	P2: 
		BEGIN		
		
			DECLARE C1 CURSOR WITH RETURN FOR SELECT * FROM SESSION.TEMP_GEGEVENS; 		

INSERT INTO SESSION.TEMP_GEGEVENS (GEAD_ID, GEAD_EORI) VALUES (1111111111, 'NL111111111'); SET H_AANTAL = H_AANTAL + 1; 
					
			SELECT COUNT(*) INTO IPARID FROM SESSION.TEMP_GEGEVENS;    

			SET STOPPEN_BIJ = H_AANTAL;
			SET TELLER = 0;
			OPEN C1;
			WHILE TELLER <  STOPPEN_BIJ
			DO		   
				FETCH C1 INTO H_GEAD_ID, H_GEAD_EORI;
				
				SELECT COUNT(*) INTO GEAD_OK FROM GEADRESSEERDE WHERE ID = H_GEAD_ID;
				
				IF GEAD_OK > 0	
				THEN 

-- TOEVOEGEN NIEUWE GEADRESSEERDE 
 
					INSERT INTO GEADRESSEERDE (ID, VERSION, GEADRESSEERDETYPE, IDENTIFICATIE, OMSCHRIJVING, GROEP, VOORKEURSADRES, EINDDATUMAUTORISATIE, USERID, DATUMTIJD)
					SELECT NEXTVAL FOR SEQBERICHT, 1, G.GEADRESSEERDETYPE, H_GEAD_EORI, G.OMSCHRIJVING, G.GROEP, G.VOORKEURSADRES, G.EINDDATUMAUTORISATIE, H_USERID, CURRENT TIMESTAMP
					FROM GEADRESSEERDE AS G                             
					WHERE G.ID = H_GEAD_ID; 
			   
					SET S_GEADRESSEERDE_ID = SEQBERICHT.CURRVAL; 
		  
-- TOEVOEGEN NIEUWE ADRESKENMERKEN, IS KOPIE VAN BRON     
                                                                  
					INSERT INTO ADRESKENMERK (GEADRESSEERDE_ID, SOORTKENMERK, KENMERK)      
					SELECT S_GEADRESSEERDE_ID, A.SOORTKENMERK, A.KENMERK  
					FROM ADRESKENMERK AS A                              
					WHERE A.GEADRESSEERDE_ID = H_GEAD_ID;         		   
                       
-- NIEUWE LOOP VOOR HET VERWERKRN VAN MEERDERE LOGISTIEKEAFSPRAAKEXTERN BIJ EEN GEADRESSEERDE				 
					BEGIN	  
				
						DECLARE C2 CURSOR WITH RETURN FOR SELECT * FROM LOGISTIEKEAFSPRAAKEXTERN WHERE GEADRESSEERDE_ID = H_GEAD_ID;	
				
						SELECT COUNT(*) INTO STOPPEN_BIJ_2 FROM LOGISTIEKEAFSPRAAKEXTERN WHERE GEADRESSEERDE_ID = H_GEAD_ID;

						SET TELLER_2 = 0;
						OPEN C2;
						WHILE TELLER_2 <  STOPPEN_BIJ_2
							DO		   
								FETCH C2 INTO F_ID, F_VERSION, F_GEADRESSEERDE_ID, F_BERICHTSTROOM, F_BERICHTTYPE, F_KANAAL, F_BERICHTFORMAAT, F_BEGINDATUMTIJD, F_EINDDATUMTIJD, F_USERID, F_DATUMTIJD, F_CSIMSGTYPE, F_SOORTADRES, F_BEWERKING;
							          
--   MAAK NIEUWE LOGISTIEKEAFSPRAAKEXTERN AAN                        
                                                   
								INSERT INTO LOGISTIEKEAFSPRAAKEXTERN (ID, VERSION, GEADRESSEERDE_ID, BERICHTSTROOM, BERICHTTYPE , KANAAL, BERICHTFORMAAT, BEGINDATUMTIJD, EINDDATUMTIJD, USERID, DATUMTIJD, CSIMSGTYPE, SOORTADRES, BEWERKING)                           
								VALUES (NEXTVAL FOR SEQBERICHT, 1, S_GEADRESSEERDE_ID, F_BERICHTSTROOM, F_BERICHTTYPE, F_KANAAL, F_BERICHTFORMAAT, '2022-09-29 01:00:00.000000', '9999-12-31 23:59:00.000000', H_USERID, CURRENT TIMESTAMP, F_CSIMSGTYPE, F_SOORTADRES, F_BEWERKING);                           
                                                      
--   BEWAAR NIEUWE ID VAN LOGISTIEKEAFSPRAAKEXTERN    
                                                      
								SET S_LOGISTIEKEAFSPRAAKEXTERN_ID = SEQBERICHT.CURRVAL;                   
                                                      
--   MAAK NIEUWE LOGISTIEKADRESEXTERN AAN (IS KOPIE)      

								INSERT INTO LOGISTIEKADRESEXTERN (ID, VERSION, LOGISTIEKEAFSPRAAKEXTERN_ID, ELEKTRONISCHADRES, USERID, DATUMTIJD) 
								SELECT NEXTVAL FOR SEQBERICHT, 1, S_LOGISTIEKEAFSPRAAKEXTERN_ID, L.ELEKTRONISCHADRES, H_USERID, CURRENT TIMESTAMP 
								FROM LOGISTIEKADRESEXTERN AS L 
								WHERE L.LOGISTIEKEAFSPRAAKEXTERN_ID = F_ID;   
	
								SET TELLER_2 = TELLER_2 + 1;						

						END WHILE;   
			
						CLOSE C2;
				
					END;
				
				END IF; 
					   
				SET TELLER = TELLER + 1;		
				
			END WHILE;   
			
			CLOSE C1;
			
			SET H_AANTAL = H_AANTAL + IPARID;		
			SET H_AANTAL = H_AANTAL + TELLER; 
			
      BEGIN                                             
        SET O_FOUTBOODSCHAP =  
          CONCAT('VERWERKING OK: AANTAL = ',H_AANTAL);  
        SET O_FOUTBOODSCHAP = RTRIM(O_FOUTBOODSCHAP);   
      END ;  
	  
  END P2;                                                      
END P1 `

--#SET TERMINATOR ; 

GRANT EXECUTE ON PROCEDURE "DBADSP03" TO $EDBA60 ;

COMMIT;
