
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
movie_cast AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        MAX(CASE WHEN ca.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_roles
    FROM 
        cast_info ca
    JOIN 
        ranked_movies rm ON ca.movie_id = rm.movie_id
    GROUP BY 
        ca.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    mc.cast_count,
    mc.has_roles,
    rm.info_count,
    rm.keyword_count
FROM 
    ranked_movies rm
JOIN 
    movie_cast mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, mc.cast_count DESC
LIMIT 50;
