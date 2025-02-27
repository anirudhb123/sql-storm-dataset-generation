WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level 
    FROM 
        aka_title mt 
    WHERE 
        mt.kind_id = (SELECT kt.id FROM kind_type kt WHERE kt.kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 
    FROM 
        movie_link m
    JOIN
        MovieHierarchy mh ON m.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON m.linked_movie_id = mt.id
)

SELECT
    a.id AS actor_id,
    a.name AS actor_name,
    COUNT(DISTINCT cc.movie_id) AS movies_acted,
    AVG(mh.level) AS average_movie_link_level,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
JOIN 
    complete_cast cc ON cc.movie_id = c.movie_id
JOIN 
    movie_keyword mk ON mk.movie_id = c.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = c.movie_id
WHERE 
    a.name IS NOT NULL 
    AND c.nr_order IS NOT NULL
    AND (c.note IS NULL OR c.note != 'uncredited')
GROUP BY 
    a.id, a.name
HAVING 
    COUNT(DISTINCT cc.movie_id) > 5
ORDER BY 
    movies_acted DESC, average_movie_link_level ASC;
