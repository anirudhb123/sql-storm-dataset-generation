WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000 

    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh 
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3 
)

SELECT 
    A.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    AVG(DISTINCT t.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT t.title, ', ') AS movies,
    SUM(CASE WHEN A.md5sum IS NULL THEN 1 ELSE 0 END) AS null_md5_count,
    RANK() OVER (PARTITION BY A.name ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
FROM 
    aka_name A
JOIN 
    cast_info C ON A.person_id = C.person_id
JOIN 
    MovieHierarchy mh ON C.movie_id = mh.movie_id
JOIN 
    aka_title T ON mh.movie_id = T.id
WHERE 
    T.production_year IS NOT NULL
    AND (T.production_year > 2005 OR A.name LIKE '%John%') 
GROUP BY 
    A.name
HAVING 
    COUNT(DISTINCT C.movie_id) > 5 
ORDER BY 
    actor_rank, AVG(DISTINCT t.production_year) DESC;