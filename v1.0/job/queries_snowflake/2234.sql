
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.cast_names
    FROM MovieDetails md
    WHERE md.rn <= 10
),
MovieKeywords AS (
    SELECT 
        t.id AS movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id
),
FinalResults AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.total_cast,
        tm.cast_names,
        mk.keywords,
        CASE 
            WHEN tm.production_year < 2000 THEN 'Classic'
            WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM TopMovies tm
    LEFT JOIN MovieKeywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.total_cast,
    fr.cast_names,
    fr.keywords,
    fr.era
FROM FinalResults fr
WHERE fr.keywords IS NOT NULL
ORDER BY fr.production_year DESC, fr.total_cast DESC;
