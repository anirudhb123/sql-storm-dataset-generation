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
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year AS movie_year,
    COUNT(DISTINCT cc.subject_id) OVER(PARTITION BY ak.id) AS movies_count,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords_list,
    COALESCE(NULLIF(mt.production_year, 0), 'Unknown Year') AS production_year_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    ak.name IS NOT NULL
    AND mt.production_year IS NOT NULL
    AND ak.name ILIKE 'A%'  -- Filtering actors whose names start with 'A'
GROUP BY 
    ak.id, mt.title, mh.production_year
ORDER BY 
    movies_count DESC, ak.name ASC;

This query achieves the following:

1. Defines a recursive CTE (`MovieHierarchy`) to explore a hierarchy of movies linked together, filtering for movies produced in the 2000s or later.
2. Selects actor names alongside their movies, counting how many movies each actor has been in and aggregating keywords associated with those movies.
3. Utilizes a `COALESCE` function to handle null values in the production year, providing a default message when the year is unknown.
4. Applies filtering criteria to focus on actors whose names start with the letter 'A'.
5. Groups the results by actor and movie details while ordering by the number of movies in descending order and actor name in ascending order.
