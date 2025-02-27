WITH name_counts AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
), 
production_years AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT km.keyword) AS keyword_count 
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword km ON t.id = km.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_movie_info AS (
    SELECT 
        nc.actor_name,
        pm.movie_title,
        pm.production_year,
        nc.movie_count
    FROM 
        name_counts nc
    JOIN 
        cast_info ci ON nc.actor_name = ci.person_id
    JOIN 
        title pm ON ci.movie_id = pm.id
)
SELECT 
    ami.actor_name,
    ami.movie_title,
    ami.production_year,
    ami.movie_count,
    CASE WHEN pm.production_year = 2023 THEN 'Current Release'
         WHEN pm.production_year > 2020 AND pm.production_year < 2023 THEN 'Recent Release'
         ELSE 'Older Release' END AS release_category
FROM 
    actor_movie_info ami
JOIN 
    production_years pm ON ami.movie_title = pm.movie_title
WHERE 
    ami.movie_count > 5
ORDER BY 
    ami.movie_count DESC, ami.actor_name;
