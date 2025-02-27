
WITH ranked_movies AS (
    SELECT 
        a.title, 
        a.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rn,
        COALESCE(NULLIF(a.title, ''), 'Untitled') AS safe_title,
        a.id
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
movie_cast AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        SUM(CASE WHEN r.role = 'actor' THEN 1 ELSE 0 END) AS actor_count
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    rm.production_year,
    rm.safe_title,
    mc.cast_count,
    mc.actor_count,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    COUNT(DISTINCT mr.movie_id) AS linked_movies
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_cast mc ON rm.id = mc.movie_id
LEFT JOIN 
    movie_keyword mw ON mw.movie_id = mc.movie_id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
LEFT JOIN 
    movie_link ml ON ml.movie_id = mc.movie_id
LEFT JOIN 
    aka_title mr ON ml.linked_movie_id = mr.id
WHERE 
    mc.cast_count > 0 OR rm.production_year >= 2000 
GROUP BY 
    rm.production_year, rm.safe_title, mc.cast_count, mc.actor_count
HAVING 
    COUNT(DISTINCT kw.keyword) > 5
ORDER BY 
    rm.production_year DESC, rm.safe_title ASC;
