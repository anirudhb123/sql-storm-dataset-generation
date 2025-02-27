WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mlt.linked_movie_id,
        1 AS level
    FROM 
        title mt
    LEFT JOIN 
        movie_link mlt ON mt.id = mlt.movie_id
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        th.id AS movie_id,
        th.title AS movie_title,
        th.production_year,
        mlt.linked_movie_id,
        mh.level + 1
    FROM 
        title th
    JOIN 
        movie_link mlt ON th.id = mlt.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.linked_movie_id = th.id
)
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    mh.movie_title AS linked_movie_title,
    mh.production_year AS linked_movie_year,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY mh.production_year DESC) AS linking_order,
    COALESCE(ci.note, 'No role specified') AS role_note
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = t.id
WHERE 
    a.name IS NOT NULL 
    AND (ci.note IS NULL OR ci.note <> '')
ORDER BY 
    actor_name,
    linking_order;
