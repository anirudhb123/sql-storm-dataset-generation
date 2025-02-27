WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        a.name AS actor_name,
        p.info AS actor_info
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN person_info p ON a.person_id = p.person_id AND p.info_type_id = 1
    WHERE t.production_year > 2000 AND c.country_code = 'USA'
),
aggregated_data AS (
    SELECT 
        production_year,
        COUNT(DISTINCT title) AS total_movies,
        COUNT(DISTINCT actor_name) AS total_actors,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM movie_details
    GROUP BY production_year
)
SELECT 
    production_year,
    total_movies,
    total_actors,
    companies,
    keywords
FROM aggregated_data
ORDER BY production_year DESC
LIMIT 10;
