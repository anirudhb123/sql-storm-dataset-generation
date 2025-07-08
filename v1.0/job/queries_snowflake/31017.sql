
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level,
        m.id AS root_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title AS movie_title,
        e.production_year,
        mh.level + 1 AS level,
        mh.root_id
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        c.movie_id
),
movies_with_cast AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.level,
        COALESCE(mc.actor_count, 0) AS actor_count,
        COALESCE(mc.actor_names, 'No actors') AS actor_names
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_cast mc ON mh.movie_id = mc.movie_id
)
SELECT 
    mwc.movie_title,
    mwc.production_year,
    mwc.level,
    mwc.actor_count,
    mwc.actor_names,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
FROM 
    movies_with_cast mwc
LEFT JOIN 
    movie_keyword mk ON mwc.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    mwc.production_year >= 2000
    AND mwc.actor_count > 0
GROUP BY 
    mwc.movie_id, mwc.movie_title, mwc.production_year, mwc.level, mwc.actor_count, mwc.actor_names
HAVING 
    COUNT(DISTINCT k.id) > 2
ORDER BY 
    mwc.production_year DESC, mwc.actor_count DESC;
