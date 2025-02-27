WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_actor_info AS (
    SELECT 
        t.id AS movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.nr_order) AS role_count
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, a.name
),
company_stats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title AS Movie_Title,
    rm.production_year AS Production_Year,
    COALESCE(ma.actor_name, 'No Actor') AS Lead_Actor,
    COALESCE(ms.company_count, 0) AS Number_of_Companies,
    CASE 
        WHEN ma.role_count > 5 THEN 'Veteran Actor'
        WHEN ma.role_count BETWEEN 1 AND 5 THEN 'Newcomer'
        ELSE 'Unknown'
    END AS Actor_Status
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_actor_info ma ON rm.movie_id = ma.movie_id
LEFT JOIN 
    company_stats ms ON rm.movie_id = ms.movie_id
WHERE 
    (rm.rank = 1 OR rm.production_year > 2000)
ORDER BY 
    rm.production_year DESC, Number_of_Companies DESC;
