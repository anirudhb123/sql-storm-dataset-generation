WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        c.name AS company_name,
        k.keyword AS movie_keyword
    FROM title m
    JOIN cast_info ci ON m.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
    JOIN movie_companies mc ON m.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE m.production_year >= 2000
    AND a.name IS NOT NULL
),
aggregated_data AS (
    SELECT 
        movie_id,
        title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT actor_role, ', ') AS roles,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM movie_data
    GROUP BY movie_id, title, production_year
)
SELECT 
    movie_id,
    title,
    production_year,
    actors,
    roles,
    companies,
    keywords
FROM aggregated_data
ORDER BY production_year DESC, title ASC
LIMIT 50;
