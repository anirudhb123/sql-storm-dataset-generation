WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(CASE 
            WHEN YEAR(h.production_year) IS NULL THEN 0
            ELSE YEAR(h.production_year)
        END) AS average_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM 
    MovieHierarchy mh
JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
JOIN 
    aka_name ak ON ak.person_id = ci.person_id 
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget')
    AND mh.production_year BETWEEN 2000 AND 2020
GROUP BY 
    mk.keyword
HAVING
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    movie_count DESC
LIMIT 10;
