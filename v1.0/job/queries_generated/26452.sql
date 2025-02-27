WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT a.name) AS actors
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY t.id, t.title, t.production_year, c.name
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_name,
    COUNT(md.actors) AS actor_count,
    STRING_AGG(DISTINCT md.keywords, ', ') AS all_keywords
FROM MovieDetails md
GROUP BY md.movie_id, md.title, md.production_year, md.company_name
HAVING COUNT(md.actors) >= 5
ORDER BY md.production_year DESC, actor_count DESC;
