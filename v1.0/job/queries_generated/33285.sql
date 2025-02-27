WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title, 
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        lb.title,
        lb.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
        JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
        JOIN aka_title lb ON ml.linked_movie_id = lb.id
)
SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    mh.depth AS hierarchy_depth,
    at.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
WHERE 
    ci.nr_order = 1 
    AND a.name IS NOT NULL 
    AND at.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, at.title, mh.depth, at.production_year
ORDER BY 
    hierarchy_depth DESC, keyword_count DESC, actor_name;

