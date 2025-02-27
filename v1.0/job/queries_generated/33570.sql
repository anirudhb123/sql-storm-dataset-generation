WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rn
    FROM 
        movie_hierarchy mh
    WHERE 
        mh.level <= 3
),
cast_count AS (
    SELECT
        c.movie_id,
        COUNT(c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
movie_details AS (
    SELECT 
        tm.movie_id,
        tm.movie_title,
        tm.production_year,
        COALESCE(cc.actor_count, 0) AS actor_count,
        CASE 
            WHEN cc.actor_count > 10 THEN 'Large Cast'
            WHEN cc.actor_count BETWEEN 5 AND 10 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM 
        top_movies tm
    LEFT JOIN 
        cast_count cc ON tm.movie_id = cc.movie_id
    WHERE
        tm.rn <= 5
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.actor_count,
    md.cast_size,
    ARRAY_AGG(DISTINCT c.name) AS actors,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    movie_details md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    aka_name c ON ci.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    md.movie_id, md.movie_title, md.production_year, md.actor_count, md.cast_size
ORDER BY 
    md.actor_count DESC, md.production_year DESC;
