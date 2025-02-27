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
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 3 -- Limit the depth of the recursion.
)

SELECT 
    ak.person_id,
    ak.name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    ARRAY_AGG(DISTINCT mh.title) AS movie_titles,
    AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) END) AS avg_info_length,
    MAX(mh.production_year) AS latest_production_year,
    MAX(CASE WHEN ci.note IS NOT NULL THEN ci.note ELSE 'No Note' END) AS cast_note
FROM 
    aka_name ak
INNER JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary' LIMIT 1)
GROUP BY 
    ak.person_id, ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5 -- More than 5 movies
ORDER BY 
    total_movies DESC, latest_production_year DESC;
