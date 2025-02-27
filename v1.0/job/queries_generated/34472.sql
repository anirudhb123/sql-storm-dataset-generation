WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        mt.season_nr,
        mt.episode_nr,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.season_nr,
        mt.episode_nr,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    h.season_nr,
    h.episode_nr,
    COALESCE(p.info, 'No Info Available') AS person_info,
    COUNT(DISTINCT ci.person_id) OVER (PARTITION BY h.movie_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
FROM 
    MovieHierarchy h
LEFT JOIN 
    complete_cast cc ON cc.movie_id = h.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = h.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    person_info p ON p.person_id = ci.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography' LIMIT 1)
WHERE 
    h.level <= 2
GROUP BY 
    h.movie_id, h.title, h.production_year, h.season_nr, h.episode_nr, p.info
ORDER BY 
    h.production_year DESC, total_cast DESC;
