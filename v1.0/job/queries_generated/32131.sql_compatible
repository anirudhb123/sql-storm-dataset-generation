
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS title, 
        m.production_year, 
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id, 
        m.title AS title, 
        m.production_year, 
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
cast_roles AS (
    SELECT 
        c.movie_id,
        r.role AS role_title, 
        COUNT(c.person_id) AS num_cast
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
average_cast AS (
    SELECT 
        movie_id,
        AVG(num_cast) AS avg_cast_size
    FROM 
        cast_roles
    GROUP BY 
        movie_id
),
movie_keywords AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    mh.title,
    mh.production_year,
    COALESCE(ac.avg_cast_size, 0) AS average_cast_size,
    mh.depth,
    mk.keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    average_cast ac ON mh.movie_id = ac.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.depth = 0 
ORDER BY 
    mh.production_year DESC, 
    mh.title ASC
LIMIT 10;
