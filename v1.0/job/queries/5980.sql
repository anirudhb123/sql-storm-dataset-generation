
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COUNT(DISTINCT p.id) AS actor_count
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON ci.movie_id = t.id AND ci.id = cc.subject_id
    JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN person_info p ON p.person_id = ci.person_id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.title, t.production_year, c.name
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_name,
    md.keywords,
    md.actors,
    md.actor_count
FROM MovieDetails md
WHERE md.actor_count > 5
ORDER BY md.production_year DESC, md.actor_count DESC;
