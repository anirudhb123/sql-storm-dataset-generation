
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
actor_movie_count AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
), 
company_movie_counts AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS total_movies
    FROM 
        movie_companies mc
    GROUP BY 
        mc.company_id
)
SELECT 
    ak.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    COALESCE(amc.movie_count, 0) AS actor_movies,
    COALESCE(cmc.total_movies, 0) AS company_movies,
    COALESCE(amc.movie_count, 0) - COALESCE(cmc.total_movies, 0) AS difference
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    ranked_movies rm ON ci.movie_id = rm.movie_id
LEFT JOIN 
    actor_movie_count amc ON ak.person_id = amc.person_id 
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_movie_counts cmc ON mc.company_id = cmc.company_id
WHERE 
    rm.title IS NOT NULL 
    AND (rm.production_year > 2000 OR cmc.total_movies IS NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
