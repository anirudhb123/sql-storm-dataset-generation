WITH movie_keyword_count AS (
    SELECT mk.movie_id, COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
actor_movie_count AS (
    SELECT ci.movie_id, COUNT(ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
joined_data AS (
    SELECT 
        t.title,
        t.production_year,
        mkc.keyword_count,
        amc.actor_count,
        ARRAY_AGG(DISTINCT an.name) AS actor_names
    FROM 
        title t
    LEFT JOIN 
        movie_keyword_count mkc ON t.id = mkc.movie_id
    LEFT JOIN 
        actor_movie_count amc ON t.id = amc.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        t.title, t.production_year, mkc.keyword_count, amc.actor_count
)
SELECT 
    j.title,
    j.production_year,
    COALESCE(j.keyword_count, 0) AS total_keywords,
    COALESCE(j.actor_count, 0) AS total_actors,
    CASE 
        WHEN j.actor_count > 0 THEN ARRAY_TO_STRING(j.actor_names, ', ')
        ELSE 'No actors'
    END AS actor_list
FROM 
    joined_data j
WHERE 
    j.production_year >= 2000
ORDER BY 
    j.total_keywords DESC,
    j.production_year DESC;
