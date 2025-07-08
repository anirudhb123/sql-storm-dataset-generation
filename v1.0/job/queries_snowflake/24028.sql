
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year = (SELECT MAX(production_year) FROM aka_title)
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    a.name AS actor_name,
    LISTAGG(DISTINCT at.title || ' (' || at.production_year || ')', ', ') WITHIN GROUP (ORDER BY at.title) AS movies,
    COUNT(DISTINCT mh.movie_id) AS linked_movies_count,
    MAX(mh.production_year) AS latest_linked_movie_year
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
    AND a.name NOT ILIKE '%unknown%'  
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT at.id) > 1 
    OR COUNT(DISTINCT mh.movie_id) > 0  
ORDER BY 
    latest_linked_movie_year DESC NULLS LAST,
    linked_movies_count DESC,
    actor_name;
