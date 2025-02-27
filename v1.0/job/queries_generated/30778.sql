WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY at.production_year DESC) AS rank,
    COALESCE(p.info, 'No info') AS actor_info,
    mh.level AS movie_level
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON at.id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON p.person_id = a.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'biography')
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = at.id
WHERE 
    at.production_year > 2000 
    AND (k.keyword IS NOT NULL OR a.md5sum IS NOT NULL)
GROUP BY 
    a.name, at.title, at.production_year, p.info, mh.level
HAVING 
    COUNT(DISTINCT mk.movie_id) > 1
ORDER BY 
    rank, at.production_year DESC;
