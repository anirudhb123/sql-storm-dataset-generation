WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 3 -- Limit depth of the hierarchy
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(COALESCE(mti.rating, 0)) AS avg_rating,
    STRING_AGG(DISTINCT at.title, ', ') AS linked_titles,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mti ON mh.movie_id = mti.movie_id 
    AND mti.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
LEFT JOIN 
    aka_title at ON mh.movie_id = at.id
WHERE 
    a.name IS NOT NULL
    AND a.name NOT LIKE '%NULL%'
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 2
ORDER BY 
    movie_count DESC, avg_rating DESC;
