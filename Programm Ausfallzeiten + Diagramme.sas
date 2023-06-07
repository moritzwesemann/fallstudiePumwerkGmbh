/* Importiert die Daten aus einer Excel-Datei */
PROC IMPORT DATAFILE='/home/u63451003/Big Data Modul/Beispieldaten Produktion Quartal 1.xlsx'
            OUT=work.Ausfallzeiten_raw
            DBMS=XLSX
            REPLACE;
            GETNAMES=YES;
RUN;

/* Entfernt Zeilen mit fehlenden Werten und formatiert die Zeitangaben in Minuten */
DATA work.Ausfallzeiten_mod;
    SET work.Ausfallzeiten_raw (KEEP=Werkzeugnummer Werkzeugtyp Produktionslinie Ausfallzeit Ausfallzeit_Einheit Ausfallgrund Reparaturdauer Reparaturdauer_Einheit Ausfalldatum);
    IF NOT MISSING(Werkzeugnummer) AND NOT MISSING(Werkzeugtyp) AND NOT MISSING(Produktionslinie) AND NOT MISSING(Ausfallzeit) AND NOT MISSING(Ausfallzeit_Einheit) AND NOT MISSING(Ausfallgrund) AND NOT MISSING(Reparaturdauer) AND NOT MISSING(Reparaturdauer_Einheit) AND NOT MISSING(Ausfalldatum);

    /* Umrechnet Stunden in Minuten, wenn die Ausfallzeit in Stunden angegeben ist */
    IF Ausfallzeit_Einheit = 'h' THEN DO;
        Ausfallzeit = Ausfallzeit * 60; 
        Ausfallzeit_Einheit = 'min'; 
    END;

    /* Umrechnet Stunden in Minuten, wenn die Reparaturdauer in Stunden angegeben ist */
    IF Reparaturdauer_Einheit = 'h' THEN DO;
        Reparaturdauer = Reparaturdauer * 60; 
        Reparaturdauer_Einheit = 'min'; 
    END;

    /* Legt das Anzeigeformat für die Zeiten in Minuten fest */
    FORMAT Ausfallzeit Reparaturdauer BEST12.2;
RUN;

/* Sortiert die Tabelle nach dem Ausfalldatum */
PROC SORT DATA=work.Ausfallzeiten_mod;
    BY Ausfalldatum;
RUN;


/* Gibt die bereinigte und formatierte Tabelle aus */
PROC PRINT DATA=Ausfallzeiten_mod;
RUN;

/* Tabellen für Graphen erstellen */

/* Erstellt eine Tabelle für die Anzahl der Ausfälle pro Produktionslinien */
PROC FREQ DATA=work.Ausfallzeiten_mod NOPRINT;
    TABLES Produktionslinie / OUT=work.Produktionslinie_freq;
RUN;

/* Aggregierte Tabelle erstellen für Werkzeugtypen mit mehrfachen Ausfällen */
PROC SQL;
    CREATE TABLE work.Werkzeug_agg AS
    SELECT Werkzeugtyp, COUNT(DISTINCT Werkzeugnummer) AS Anzahl_Ausfalle, SUM(Ausfallzeit/60) AS Gesamt_Ausfallzeit
    FROM work.Ausfallzeiten_mod
    WHERE Werkzeugtyp IS NOT NULL
    GROUP BY Werkzeugtyp
    HAVING COUNT(DISTINCT Werkzeugnummer) > 1;
QUIT;



/* Erstellt ein Balkendiagramm der Gesamtzahl der Störungen pro Produktionslinie */
PROC SGPLOT DATA=work.Produktionslinie_freq;
    VBAR Produktionslinie / RESPONSE=COUNT;
    TITLE 'Anzahl der Störungen pro Produktionslinie';
RUN;



/* Balkendiagramm der Anzahl der Ausfälle und Gesamtausfallzeit pro Werkzeugtyp */
PROC SGPLOT DATA=work.Werkzeug_agg;
    VBAR Werkzeugtyp / RESPONSE=Anzahl_Ausfalle GROUP= Gesamt_Ausfallzeit;
    XAXIS DISPLAY=(nolabel);
    YAXIS LABEL='Anzahl der Ausfälle / Gesamtausfallzeit (h)';
    KEYLEGEND / LOCATION=outside POSITION=bottom TITLE='Werkzeugtyp (Werte in h)';
    TITLE 'Anzahl der Ausfälle und Gesamtausfallzeit pro Werkzeugtyp (für Werkzeugtypen mit mehr als einem Ausfall)';
RUN;

