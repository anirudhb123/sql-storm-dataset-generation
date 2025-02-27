WITH movie_statistics AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        STRING_AGG(DISTINCT comp.name, ', ') AS companies
    FROM title t
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info c ON cc.subject_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name comp ON mc.company_id = comp.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.actor_count,
    ms.keyword_count,
    COALESCE(NULLIF(ms.companies, ''), 'No companies listed') AS companies
FROM movie_statistics ms
WHERE ms.actor_count > 5 AND ms.keyword_count > 2
ORDER BY ms.production_year DESC, ms.actor_count DESC;
