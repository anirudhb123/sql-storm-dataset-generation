WITH MovieInfo AS (
    SELECT 
        t.title AS movie_title, 
        t.production_year, 
        c.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type c ON mc.company_type_id = c.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY t.title, t.production_year, c.kind
),
FilteredMovies AS (
    SELECT *
    FROM MovieInfo
    WHERE production_year >= 2000 
      AND cast_count > 5
)

SELECT 
    *,
    CASE 
        WHEN cast_count > 10 THEN 'Star-studded'
        WHEN cast_count BETWEEN 6 AND 10 THEN 'Ensemble Cast'
        ELSE 'Minimal Cast'
    END AS cast_category
FROM FilteredMovies
ORDER BY production_year DESC, movie_title;
