
WITH movie_actors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.id) AS total_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
), 
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
), 
movies_info AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.keywords,
        ma.actor_name,
        ma.total_roles
    FROM 
        movies_with_keywords mwk
    JOIN 
        movie_actors ma ON mwk.movie_id = ma.movie_id
)
SELECT 
    mi.title,
    mi.keywords,
    mi.actor_name,
    mi.total_roles
FROM 
    movies_info mi
WHERE 
    mi.total_roles > 1
AND 
    mi.keywords @> ARRAY['drama', 'action']
ORDER BY 
    mi.total_roles DESC, 
    mi.title;
