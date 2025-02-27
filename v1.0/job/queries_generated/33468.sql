WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000 -- filter for movies released in the 21st century

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS average_order,
    string_agg(DISTINCT ak.name, ', ') AS all_actors,
    coalesce(MAX(mk.keyword), 'None') AS top_keyword,
    RANK() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS cast_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
WHERE 
    mh.level = 1
GROUP BY 
    mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) >= 5 -- only movies with 5 or more distinct cast members
ORDER BY 
    cast_rank ASC, mh.production_year DESC;

