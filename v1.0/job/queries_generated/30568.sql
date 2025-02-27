WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::text AS parent_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.title AS parent_title,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.linked_movie_id
)
SELECT 
    mk.keyword,
    m.title AS movie_title,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    AVG(YEAR(CURRENT_DATE) - m.production_year) AS avg_movie_age,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
FROM 
    MovieHierarchy mh
JOIN 
    aka_title m ON m.id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
WHERE 
    mh.level = 1 -- only top-level movies
    AND mk.keyword IS NOT NULL
    AND m.production_year IS NOT NULL
    AND mk.keyword NOT LIKE '%%s' -- example exclusion pattern
GROUP BY 
    mk.keyword, m.title
HAVING 
    COUNT(DISTINCT ci.person_id) > 3 -- at least 4 actors
ORDER BY 
    actor_count DESC, avg_movie_age DESC;
