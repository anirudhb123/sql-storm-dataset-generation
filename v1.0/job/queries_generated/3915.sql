WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_counts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
actors_info AS (
    SELECT 
        ak.name AS actor_name,
        a.movie_id,
        r.role,
        COUNT(*) OVER (PARTITION BY ak.id) AS actor_movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    rm.title,
    rm.production_year,
    ai.actor_name,
    ai.role,
    ai.actor_movies_count,
    COALESCE(amc.movie_count, 0) AS total_movies_by_actor,
    CASE 
        WHEN amc.movie_count > 5 THEN 'Experienced Actor'
        ELSE 'New Actor'
    END AS actor_experience_level
FROM 
    ranked_movies rm
LEFT JOIN 
    actors_info ai ON rm.movie_id = ai.movie_id
LEFT JOIN 
    actor_movie_counts amc ON ai.person_id = amc.person_id
WHERE 
    rm.year_rank <= 3 
    AND (rm.production_year > 2000 OR ai.actor_name IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    total_movies_by_actor DESC, 
    ai.actor_name;
