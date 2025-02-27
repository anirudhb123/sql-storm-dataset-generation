WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

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
        aka_title at ON ml.linked_movie_id = at.movie_id
)

SELECT 
    a.name AS Actor_Name,
    mt.title AS Movie_Title,
    mt.production_year AS Production_Year,
    COUNT(DISTINCT cc.person_id) OVER (PARTITION BY mt.id) AS Total_Actors,
    STRING_AGG(DISTINCT pi.info || ': ' || pi.note, '; ') FILTER (WHERE pi.info IS NOT NULL) AS Info_Notes
FROM 
    MovieHierarchy mh
JOIN 
    cast_info cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name a ON cc.person_id = a.person_id
JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    person_info pi ON cc.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography' LIMIT 1)
JOIN 
    aka_title mt ON mh.movie_id = mt.movie_id
WHERE 
    a.name IS NOT NULL
  AND 
    mh.level <= 3
  AND 
    mt.production_year IS NOT NULL
ORDER BY 
    Production_Year DESC, Total_Actors DESC;


