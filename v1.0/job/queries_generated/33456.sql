WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    ak.id AS actor_id,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(*) OVER (PARTITION BY ak.id, mh.production_year) AS total_movies,
    SUM(CASE 
        WHEN ci.role_id IS NOT NULL THEN 1 
        ELSE 0 
    END) AS roles_count,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    COALESCE(MAX(mo.info), 'No info available') AS movie_info
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    movie_info mo ON mh.movie_id = mo.movie_id
WHERE 
    mh.production_year > 2000 
    AND (ci.note IS NULL OR ci.note != 'Cameo')
GROUP BY 
    ak.id, mh.title, mh.production_year
ORDER BY 
    total_movies DESC, 
    actor_name ASC;
