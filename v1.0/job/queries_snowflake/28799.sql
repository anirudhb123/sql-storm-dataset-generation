WITH movie_data AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        a.name AS actor_name
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
        AND c.country_code = 'USA'
),
keyword_counts AS (
    SELECT 
        title_id,
        COUNT(DISTINCT keyword) AS unique_keywords
    FROM movie_data
    GROUP BY title_id
),
actor_counts AS (
    SELECT 
        title_id,
        COUNT(DISTINCT actor_name) AS unique_actors
    FROM movie_data
    GROUP BY title_id
)
SELECT 
    m.title_id,
    m.title,
    m.production_year,
    kc.unique_keywords,
    ac.unique_actors
FROM movie_data m
JOIN keyword_counts kc ON m.title_id = kc.title_id
JOIN actor_counts ac ON m.title_id = ac.title_id
ORDER BY 
    m.production_year DESC,
    kc.unique_keywords DESC,
    ac.unique_actors DESC;
