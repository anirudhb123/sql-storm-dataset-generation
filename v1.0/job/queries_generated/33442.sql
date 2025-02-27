WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        NULL::integer AS parent_id,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000  -- Starting from movies released in the year 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COALESCE(aka.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS cast_count,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.production_year DESC) AS movie_rank,
    (SELECT AVG(m.production_year) FROM aka_title m WHERE m.production_year IS NOT NULL) AS avg_production_year,
    CASE 
        WHEN mh.level > 0 THEN 'Linked'
        ELSE 'Standalone'
    END AS movie_type
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name aka ON aka.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, aka.name, mh.level
HAVING 
    COUNT(DISTINCT mk.keyword) > 3  -- Having more than 3 distinct keywords
ORDER BY 
    mh.production_year DESC, movie_rank;
