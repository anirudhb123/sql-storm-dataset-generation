WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        CAST(NULL AS VARCHAR) AS parent_movie,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        lm.title AS movie_title,
        lm.production_year,
        mh.movie_title AS parent_movie,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title lm ON ml.linked_movie_id = lm.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_title,
    mh.production_year,
    mh.parent_movie,
    mh.level,
    COUNT(DISTINCT c.id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    SUM(CASE 
        WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') THEN CAST(mi.info AS NUMERIC)
        ELSE 0 
    END) AS total_box_office
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
GROUP BY 
    mh.movie_title, mh.production_year, mh.parent_movie, mh.level
HAVING 
    COUNT(DISTINCT c.id) > 0
ORDER BY 
    mh.level, mh.production_year DESC;

This query uses a recursive CTE to build a hierarchy of movies based on links between them, counts the distinct actors in each movie, aggregates their names into a single string, and calculates the total box office income for each movie, while filtering the results to exclude movies with no cast. The output is ordered by the hierarchy level and year of production, allowing for an interesting performance benchmarking across different movies over time.
