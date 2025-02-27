WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') AND mt.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        lt.title AS movie_title,
        lt.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        title lt ON ml.linked_movie_id = lt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') THEN CAST(mi.info AS NUMERIC) END) AS average_budget,
    MAX(mi.note) AS last_note
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = c.person_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 5
ORDER BY 
    mh.production_year DESC, actor_count DESC;
