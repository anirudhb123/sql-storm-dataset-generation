WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mm.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link mm
    JOIN 
        aka_title m ON mm.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mm.movie_id = mh.movie_id
)
, movie_cast AS (
    SELECT 
        c.id AS cast_info_id,
        c.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        ROW_NUMBER() OVER(PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
)
, keyword_filter AS (
    SELECT 
        mw.movie_id,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        movie_keyword mw
    JOIN 
        keyword kw ON mw.keyword_id = kw.id
    GROUP BY 
        mw.movie_id
    HAVING 
        COUNT(DISTINCT kw.keyword) > 5
)
SELECT 
    mh.title,
    mh.production_year,
    ARRAY_AGG(DISTINCT mk.keyword_count) AS keyword_count,
    ARRAY_AGG(DISTINCT mc.actor_name) AS top_actors,
    AVG(mc.role_order) AS average_role_order 
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_cast mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    keyword_filter mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2020
    AND (mh.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Drama%') 
         OR mh.title ILIKE '%Award%')
GROUP BY 
    mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.actor_name) > 3
ORDER BY 
    average_role_order DESC NULLS LAST;
