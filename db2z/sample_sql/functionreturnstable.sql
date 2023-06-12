CREATE FUNCTION SCHEMA (
        SQL XML
)
RETURNS TABLE(
        SCHEMA VARCHAR(8)
)
DETERMINISTIC
NO EXTERNAL ACTION
READS SQL DATA
RETURN SELECT
        SCHEMA
FROM XMLTABLE('//setSchemaStatement[1]/expression/columnName/identifier1/sqlidentifier/input'
    PASSING BY REF SQL
    COLUMNS
        "SCHEMA" VARCHAR(8) PATH 'text()' WITH DEFAULT 'NOBODY'
)
;




CREATE FUNCTION DDL0130_V1 (
        SQL XML,
        RULE_DATE DATE
)
RETURNS TABLE (
        STARTLINE INTEGER,
        STARTCOLUMN INTEGER,
        ENDLINE INTEGER,
        ENDCOLUMN INTEGER,
        RULEID VARCHAR(40),
        MESSAGE VARCHAR(256)
)
LANGUAGE SQL
RETURN SELECT
   STARTLINE,
   STARTCOLUMN,
   STARTLINE AS ENDLINE,
   STARTCOLUMN + COL_LENGTH AS ENDCOLUMN,
   'DDL0130' AS RULEID,
   'PRIQTY is verplicht bij het maken van een INDEX of TABLESPACE en hoort de waarde -1 te hebben. Bij het aanpassen van een INDEX of TABLESPACE is PRIQTY optioneel, maar indien aanwezig, behoort deze de waarde -1 te hebben.' AS MESSAGE
FROM (
        -- WITH WRONG VALUE
        SELECT
                STARTLINE,
                STARTCOLUMN,
                COL_LENGTH,
                OBJ_NAME,
                'INDEX' AS OBJ_TYPE
        FROM XMLTABLE(
                '//sqlStatement/createIndexStatement/createIndexOptionList'
                PASSING BY REF SQL
                COLUMNS
                        "STMT" XML PATH '.',
			                        "STARTLINE" INTEGER PATH 'usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1]/@line',
                        "STARTCOLUMN" INTEGER PATH 'usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1]/@position',
                        "COL_LENGTH" INTEGER WITH DEFAULT -1  PATH 'string-length(usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1])',
                        "OBJ_NAME" VARCHAR(40) PATH 'usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1]/../../../../indexName/identifier/sqlidentifier/input[text()]'
        )
        WHERE XMLEXISTS('usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1]'
                PASSING BY REF STMT
        )
        UNION
        -- NOT SET AT ALL
        SELECT
                STARTLINE,
                STARTCOLUMN,
                COL_LENGTH,
                OBJ_NAME,
                'INDEX' AS OBJ_TYPE
        FROM XMLTABLE(
                '//sqlStatement/createIndexStatement'
                PASSING BY REF SQL
                COLUMNS
                        "STMT" XML PATH '.',
                        "STARTLINE" INTEGER PATH 'input[text() = "CREATE"]/@line',
                        "STARTCOLUMN" INTEGER PATH 'input[text() = "CREATE"]/@position',
                        "COL_LENGTH" INTEGER WITH DEFAULT -1  PATH 'string-length(input[text() = "CREATE"])',
                        "OBJ_NAME" VARCHAR(40) PATH 'indexName/identifier/sqlidentifier/input[text()]'
        )
        WHERE NOT XMLEXISTS('createIndexOptionList/usingSpecification1/input[text()="PRIQTY"]'
                PASSING BY REF STMT
        )
        UNION
        -- OPTIONAL SET WITH WRONG VALUE
        SELECT
	                STARTLINE,
                STARTCOLUMN,
                COL_LENGTH,
                OBJ_NAME,
                'INDEX' AS OBJ_TYPE
        FROM XMLTABLE(
                '//sqlStatement/alterIndexStatement/alterIndexOptions/usingBlock'
                PASSING BY REF SQL
                COLUMNS
                        "STMT" XML PATH '.',
                        "STARTLINE" INTEGER PATH 'usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1]/@line',
                        "STARTCOLUMN" INTEGER PATH 'usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1]/@position',
                        "COL_LENGTH" INTEGER WITH DEFAULT -1  PATH 'string-length(usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1])',
                        "OBJ_NAME" VARCHAR(40) PATH 'usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1]/../../../../indexName/identifier/sqlidentifier/input[text()]'
        )
        WHERE XMLEXISTS('usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1]'
                PASSING STMT
        )
        UNION
        -- WITH WRONG VALUE
        SELECT
                STARTLINE,
                STARTCOLUMN,
                COL_LENGTH,
                OBJ_NAME,
                'TABLESPACE' AS OBJ_TYPE
        FROM XMLTABLE(
                '//sqlStatement/createTablespaceStatement/createTablespaceOptionList/usingSpecification2'
                PASSING BY REF SQL
                COLUMNS
                        "STMT" XML PATH '.',
                        "STARTLINE" INTEGER PATH 'stogroupOptions[input[text()="PRIQTY"]]/input[2][text()!=-1]/@line',
                        "STARTCOLUMN" INTEGER PATH 'stogroupOptions[input[text()="PRIQTY"]]/input[2][text()!=-1]/@position',
			                        "COL_LENGTH" INTEGER WITH DEFAULT -1  PATH 'string-length(stogroupOptions[input[text()="PRIQTY"]]/input[2][text()!=-1])',
                        "OBJ_NAME" VARCHAR(40) PATH 'stogroupOptions[input[text()="PRIQTY"]]/input[2][text()!=-1]/../../../../tablespaceName/identifier/sqlidentifier/input[text()]'
        )
        WHERE XMLEXISTS('stogroupOptions[input[text()="PRIQTY"]]/input[2][text()!=-1]'
                PASSING BY REF STMT
        )
        UNION
        -- NOT SET AT ALL
        SELECT
                STARTLINE,
                STARTCOLUMN,
                COL_LENGTH,
                OBJ_NAME,
                'TABLESPACE' AS OBJ_TYPE
        FROM XMLTABLE(
                '//sqlStatement/createTablespaceStatement'
                PASSING BY REF SQL
                COLUMNS
                        "STMT" XML PATH '.',
                        "STARTLINE" INTEGER PATH 'input[text() = "CREATE"]/@line',
                        "STARTCOLUMN" INTEGER PATH 'input[text() = "CREATE"]/@position',
                        "COL_LENGTH" INTEGER WITH DEFAULT -1  PATH 'string-length(input[text() = "CREATE"])',
                        "OBJ_NAME" VARCHAR(40) PATH 'tablespaceName/identifier/sqlidentifier/input[text()]'
        )
        WHERE NOT XMLEXISTS('createTablespaceOptionList/usingSpecification2/stogroupOptions/input[text()="PRIQTY"]'
                PASSING BY REF STMT
        )
        UNION
        -- OPTIONAL SET WITH WRONG VALUE
        SELECT
                STARTLINE,
                STARTCOLUMN,
                COL_LENGTH,
                OBJ_NAME,
                'TABLESPACE' AS OBJ_TYPE
        FROM XMLTABLE(
                '//sqlStatement/alterTablespaceStatement/alterTablespaceOptionList/usingBlock'
                PASSING BY REF SQL
                COLUMNS
                        "STMT" XML PATH '.',
                        "STARTLINE" INTEGER PATH 'usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1]/@line',
                        "STARTCOLUMN" INTEGER PATH 'usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1]/@position',
                        "COL_LENGTH" INTEGER WITH DEFAULT -1  PATH 'string-length(usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1])',
                        "OBJ_NAME" VARCHAR(40) PATH 'usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1]/../../../../tablespaceName/identifier/sqlidentifier/input[text()]'
        )
        WHERE XMLEXISTS('usingSpecification1[input[text()="PRIQTY"]]/input[2][text()!=-1]'
                PASSING STMT
        )
)
WHERE OBJ_NAME NOT IN (
   SELECT E.OBJ_NAME
   FROM VALIDATION_EXCEPTIONS AS E
   WHERE E.SCHEMA = (SELECT SCHEMA FROM TABLE(SCHEMA(SQL)))
   AND E.OBJ_TYPE = OBJ_TYPE
   AND RULE = 'DDL0130'
   AND RULE_DATE BETWEEN START_DATE AND END_DATE
)
;
