UPDATE aag_afne_groepsafspraakgebruiktvorm ogagv SET eindtijdstipgeldigheid = CURRENT TIMESTAMP
WHERE  ogagv.disabled = 'no' 
AND    ogagv.vorm_id != 
       (SELECT iv.id
        FROM  aag_afne_groepsafspraak iga
        ,     aag_afne_afspraak ia
        ,     aag_afne_cyclus ic
        ,     aag_afne_cyclusgebruiktvorm icgv
        ,     aag_gege_vorm iv
        WHERE iga.name != 'IAH'
        AND   iga.id = ia.groepsafspraak_id
        AND   ia.id = ic.afspraak_id
        AND   icgv.cyclus_id = ic.id
        AND   icgv.vorm_id = iv.id
        AND   ia.einddatum IS NULL
        AND   icgv.eindtijdstipgeldigheid IS NULL
        AND   ogagv.groepsafspraak_id = iga.id
        AND   ogagv.rapportagetijdvak = ic.rapportagetijdvak
        AND   ogagv.soort = icgv.soort
        AND   iga.disabled = 'no'
        AND   ia.disabled = 'no'
        AND   ic.disabled = 'no'
        AND   iv.disabled = 'no'
        AND   icgv.disabled = 'no'
        GROUP BY iga.id, ic.rapportagetijdvak, icgv.soort, iv.id
        ORDER BY count(*) DESC, iv.id DESC
        LIMIT 1);

