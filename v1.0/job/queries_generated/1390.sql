WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
), actor_count AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
), movie_details AS (
    SELECT 
        at.title,
        ac.actor_count,
        rm.company_count
    FROM 
        ranked_movies rm
    JOIN 
        actor_count ac ON rm.id = ac.movie_id
)
SELECT 
    md.title,
    md.actor_count,
    md.company_count,
    COALESCE(md.company_count, 0) - COALESCE(md.actor_count, 0) AS net_difference
FROM 
    movie_details md
WHERE 
    md.actor_count > (SELECT AVG(actor_count) FROM actor_count)
ORDER BY 
    net_difference DESC
LIMIT 10;
