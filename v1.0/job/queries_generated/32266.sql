WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        ARRAY[mt.title] AS path
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        path || at.title
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 10  -- Limit the depth to avoid infinite recursion
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT c.name) AS character_names,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    char_name c ON c.id = ci.role_id
WHERE 
    at.production_year > 2000 
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) >= 2
ORDER BY 
    actor_name, movie_rank;

This SQL query achieves the following:

1. Uses a recursive Common Table Expression (CTE) to build a hierarchy of linked movies up to a depth of 10.
2. Joins several tables, including `aka_name`, `cast_info`, and `aka_title`, to gather data on actors, movies, and character details.
3. Employs LEFT JOINs to include production company details and character names effectively, while ensuring that missing data does not exclude results.
4. Filters for movies produced after 2000 and ensures actor names are not null.
5. Groups the results by actor name, movie title, and production year, counting the distinct production companies involved in each movie.
6. Uses the HAVING clause to ensure only movies with at least two production companies are included.
7. Orders the final list by actor name and a calculated movie rank using ROW_NUMBER() to evaluate actor’s works over the years.
