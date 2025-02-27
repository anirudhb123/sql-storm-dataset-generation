WITH movie_data AS (
    SELECT 
        t.title AS movie_title, 
        t.production_year,
        c.name AS company_name,
        a.name AS actor_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT pi.info, '; ') AS person_info
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN person_info pi ON a.person_id = pi.person_id
    WHERE t.production_year >= 2000
    GROUP BY t.title, t.production_year, c.name, a.name
),

company_info AS (
    SELECT 
        company_name,
        COUNT(DISTINCT movie_title) AS movie_count,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors
    FROM movie_data
    GROUP BY company_name
)

SELECT 
    ci.company_name,
    ci.movie_count,
    ci.actors,
    COUNT(DISTINCT md.movie_title) AS unique_movies,
    STRING_AGG(DISTINCT md.keywords, '; ') AS all_keywords,
    STRING_AGG(DISTINCT md.person_info, '| ') AS all_person_info
FROM company_info ci
JOIN movie_data md ON ci.company_name = md.company_name
GROUP BY ci.company_name, ci.movie_count, ci.actors
ORDER BY ci.movie_count DESC;
