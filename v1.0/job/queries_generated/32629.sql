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
        mh.movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    a.name AS actor_name,
    concat('Movie Title: ', at.title, ' (', at.production_year, ')') AS movie_details,
    COUNT(c.id) AS total_roles,
    SUM(CASE WHEN (COALESCE(c.note, '') != '') THEN 1 ELSE 0 END) AS roles_with_notes,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, at.title, at.production_year
HAVING 
    COUNT(c.id) > 1 
ORDER BY 
    total_roles DESC, avg_order DESC
LIMIT 10;
