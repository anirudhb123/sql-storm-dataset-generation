WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
actor_movie_counts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT rc.movie_id) AS movie_count
    FROM 
        cast_info a
    JOIN 
        ranked_movies rm ON a.movie_id = rm.movie_id
    LEFT JOIN 
        aka_name an ON a.person_id = an.person_id
    GROUP BY 
        a.person_id
)
SELECT 
    an.name AS actor_name,
    COALESCE(amc.movie_count, 0) AS total_movies,
    RANK() OVER (ORDER BY COALESCE(amc.movie_count, 0) DESC) AS actor_rank
FROM 
    aka_name an
LEFT JOIN 
    actor_movie_counts amc ON an.person_id = amc.person_id
WHERE 
    an.name IS NOT NULL
ORDER BY 
    actor_rank
LIMIT 10;
