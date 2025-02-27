WITH MovieKeywords AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
TopMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    GROUP BY t.id, t.title, t.production_year
)
SELECT 
    tm.title, 
    tm.production_year, 
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    tn.name AS main_actor,
    COUNT(DISTINCT m.company_id) AS production_companies
FROM TopMovies tm
LEFT JOIN MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN cast_info ci ON tm.id = ci.movie_id AND ci.nr_order = 1
LEFT JOIN aka_name an ON ci.person_id = an.person_id
LEFT JOIN name tn ON an.person_id = tn.imdb_id
LEFT JOIN movie_companies m ON tm.id = m.movie_id
WHERE tm.rn <= 10
GROUP BY tm.title, tm.production_year, mk.keywords, tn.name
ORDER BY tm.production_year DESC, tm.cast_count DESC;
