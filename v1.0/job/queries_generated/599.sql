WITH ranked_movies AS (
    SELECT 
        tit.title,
        tit.production_year,
        ROW_NUMBER() OVER (PARTITION BY tit.production_year ORDER BY tit.title) AS rn
    FROM 
        aka_title AS tit
    WHERE 
        tit.production_year > 2000
),
actor_movie_counts AS (
    SELECT 
        aki.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name AS aki
    JOIN 
        cast_info AS ci ON aki.person_id = ci.person_id
    GROUP BY 
        aki.person_id
),
recent_movies AS (
    SELECT 
        tit.title,
        tit.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title AS tit
    LEFT JOIN 
        cast_info AS ci ON tit.movie_id = ci.movie_id
    WHERE 
        tit.production_year = (SELECT MAX(production_year) FROM aka_title)
    GROUP BY 
        tit.title, tit.production_year
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    COALESCE(amc.movie_count, 0) AS total_actors,
    r.actor_count AS recent_actor_count,
    (SELECT AVG(movie_count) FROM actor_movie_counts) AS avg_movies_per_actor
FROM 
    ranked_movies AS rm
LEFT JOIN 
    actor_movie_counts AS amc ON rm.title = amc.person_id::text
LEFT JOIN 
    recent_movies AS r ON rm.title = r.title
WHERE 
    rm.rn <= 10 AND (r.actor_count IS NULL OR r.actor_count > 5)
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title ASC;
