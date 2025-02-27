WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m1.id AS movie_id,
        m1.title,
        m1.production_year,
        1 AS level
    FROM 
        aka_title m1
    WHERE 
        m1.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m2.id AS movie_id,
        m2.title,
        m2.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title AS movie_title,
    AVG(CASE WHEN ca.note IS NOT NULL THEN 1 ELSE 0 END) AS actor_availability,
    GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS actor_names,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    movie_hierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    aka_name ak ON ca.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
WHERE 
    m.production_year BETWEEN 1990 AND 2023
GROUP BY 
    m.movie_id, m.title
HAVING 
    COUNT(DISTINCT ak.name) >= 2
ORDER BY 
    movie_title;

This SQL query creates a recursive Common Table Expression (CTE) to establish a hierarchy of movies and their linked titles, then aggregates data to generate a report on actor availability and associated keywords for movies produced between 1990 and 2023. It utilizes outer joins to include movies with no cast and metrics like actor count and keyword existence while performing filtering and grouping operations to ensure the quality of the results. The final result is sorted by movie title for clarity.
