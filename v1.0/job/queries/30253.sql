WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        a.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT c.person_id) AS total_actors,
    SUM(CASE WHEN p.info IS NOT NULL THEN 1 ELSE 0 END) AS total_awards,
    RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS award_rank,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_name ak ON c.person_id = ak.person_id AND ak.name IS NOT NULL
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Award')
WHERE 
    mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 2
ORDER BY 
    mt.production_year DESC, total_actors DESC;

