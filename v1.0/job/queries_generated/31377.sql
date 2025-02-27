WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movies_count,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT mh.movie_title, ', ') AS movie_titles,
    MAX(mh.depth) AS max_depth,
    COUNT(DISTINCT CASE WHEN info.info IS NOT NULL THEN info.movie_id END) AS info_count,
    SUM(CASE WHEN info.info IS NULL THEN 1 ELSE 0 END) AS no_info_count

FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    (SELECT 
        mi.movie_id, 
        mi.info 
     FROM 
        movie_info mi
     WHERE 
        mi.note IS NULL) info ON info.movie_id = mh.movie_id

WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5 AND 
    AVG(mh.production_year) < 2000 
ORDER BY 
    movies_count DESC
LIMIT 10;
