
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info c ON cc.subject_id = c.person_id
    GROUP BY t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.keywords 
    FROM RankedMovies rm
    WHERE rm.rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    (SELECT COUNT(DISTINCT pi.person_id)
     FROM person_info pi
     JOIN aka_name an ON pi.person_id = an.person_id
     JOIN name n ON an.person_id = n.imdb_id
     WHERE n.name IN (SELECT UNNEST(tm.keywords))) AS total_people,
    (SELECT COUNT(DISTINCT mc.company_id)
     FROM movie_companies mc
     WHERE mc.movie_id IN (SELECT t.id FROM title t WHERE t.title = tm.title)) AS total_companies
FROM TopMovies tm
ORDER BY tm.production_year DESC;
