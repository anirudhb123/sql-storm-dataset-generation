WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    p.name AS person_name, 
    COUNT(mc.movie_id) AS total_movies, 
    AVG(m.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY p.name ORDER BY COUNT(mc.movie_id) DESC) AS rank
FROM 
    aka_name p
LEFT JOIN 
    cast_info ci ON ci.person_id = p.person_id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = ci.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = cc.movie_id
RIGHT JOIN 
    MovieHierarchy m ON mc.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    p.name IS NOT NULL 
GROUP BY 
    p.name
HAVING 
    COUNT(mc.movie_id) > 3 AND 
    AVG(m.production_year) > 2000
ORDER BY 
    rank, total_movies DESC;
