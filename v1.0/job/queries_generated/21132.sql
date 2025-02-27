WITH RECURSIVE related_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        mk.keyword,
        1 AS level
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        mk.keyword ILIKE '%action%' -- Starting keyword for related movies
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        mk.keyword,
        rt.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        related_movies rt ON mk.keyword = rt.keyword 
    WHERE 
        rt.level < 3
),
top_movies AS (
    SELECT 
        ct.movie_id,
        COUNT(c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY ct.movie_id ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        complete_cast ct
    LEFT JOIN 
        cast_info c ON ct.movie_id = c.movie_id
    GROUP BY 
        ct.movie_id
    HAVING 
        COUNT(c.person_id) > 2
),
movie_ratings AS (
    SELECT 
        m.id AS movie_id,
        AVG(r.rating) AS avg_rating
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        (SELECT movie_id, CAST(info AS FLOAT) AS rating FROM movie_info) r ON m.id = r.movie_id
    GROUP BY 
        m.id
)
SELECT 
    rm.movie_id,
    rm.title,
    tr.actor_count,
    mr.avg_rating
FROM 
    related_movies rm
LEFT JOIN 
    top_movies tr ON rm.movie_id = tr.movie_id
LEFT JOIN 
    movie_ratings mr ON rm.movie_id = mr.movie_id
WHERE 
    tr.rn IS NOT NULL 
    AND (mr.avg_rating IS NOT NULL OR (rr.avg_rating IS NULL AND rm.title LIKE '%The%')) -- Bizarre logic combining condition
ORDER BY 
    rm.title ASC,
    tr.actor_count DESC,
    mr.avg_rating DESC;
