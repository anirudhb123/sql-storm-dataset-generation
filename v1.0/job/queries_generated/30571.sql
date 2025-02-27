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
        ak.title,
        ak.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        ak.production_year >= 2000
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    AVG(mh.level) AS avg_movie_level,
    STRING_AGG(DISTINCT ks.keyword, ', ') AS keywords,
    MIN(mt.production_year) AS earliest_movie_year,
    MAX(mt.production_year) AS latest_movie_year,
    SUM(CASE WHEN mt.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN 
    keyword ks ON mk.keyword_id = ks.id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name NOT LIKE '%test%' 
GROUP BY 
    ak.name
ORDER BY 
    total_movies DESC, 
    earliest_movie_year ASC
LIMIT 10;
