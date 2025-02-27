WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        NULL::text AS parent_title
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming kind_id = 1 is for movies

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1,
        mh.title AS parent_title
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.kind_id = 1 
)

SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    mh.parent_title,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(mk.creation_year) AS avg_creation_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keyword_list,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY COUNT(DISTINCT mk.keyword) DESC) AS actor_keyword_rank,
    COALESCE(mn.info, 'No info') AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = at.id
JOIN 
    MovieHierarchy mh ON mh.movie_id = at.id
LEFT JOIN 
    movie_info mn ON mn.movie_id = at.id AND mn.info_type_id = 1  -- Assuming info_type_id = 1 refers to some specific info
WHERE 
    mk.keyword IS NOT NULL AND 
    (at.production_year BETWEEN 2000 AND 2023 OR at.production_year IS NULL) AND
    a.name IS NOT NULL
GROUP BY 
    a.name, at.title, mh.parent_title, mn.info
HAVING 
    COUNT(DISTINCT mk.keyword) > 0
ORDER BY 
    COUNT(DISTINCT mk.keyword) DESC, 
    a.name;
