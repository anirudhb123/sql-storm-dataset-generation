WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
actor_movie_count AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)

SELECT 
    rm.title AS movie_title,
    rm.production_year,
    COALESCE(am.actor_count, 0) AS actor_count,
    rm.company_count
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_movie_count am ON rm.title_id = am.movie_id
WHERE 
    rm.rn <= 5   
ORDER BY 
    rm.production_year, rm.company_count DESC, rm.title;