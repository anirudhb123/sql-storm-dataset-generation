WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mc.depth + 1
    FROM 
        MovieCTE mc
    JOIN 
        movie_link ml ON mc.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year >= 2000
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT ak.person_id) AS actor_count,
    COUNT(DISTINCT c.movie_id) as complete_cast_count,
    AVG(COALESCE(mi.info, '0')) AS average_rating,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords
FROM 
    cast_info c
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    aka_title at ON c.movie_id = at.movie_id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    MovieCTE m ON at.id = m.movie_id
WHERE 
    at.production_year BETWEEN 2000 AND 2020
GROUP BY 
    ak.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT c.movie_id) > 1
ORDER BY 
    average_rating DESC, actor_name ASC;
