WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  -- Select Movies only
    UNION ALL
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mt ON mt.id = ml.linked_movie_id
)
SELECT
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    ARRAY_AGG(DISTINCT mh.title) AS movie_titles,
    STRING_AGG(DISTINCT CASE
        WHEN co.name IS NULL THEN 'Unknown Company'
        ELSE co.name
    END, ', ') AS company_names,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rn
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    company_name co ON mc.company_id = co.id
WHERE
    ak.name ILIKE '%Smith%'  -- Looking for actors with 'Smith' in their name
GROUP BY
    ak.id
HAVING
    COUNT(DISTINCT mh.movie_id) > 5  -- Only include actors with more than 5 movies
ORDER BY
    total_movies DESC;

This query creates a recursive common table expression (CTE) to traverse movie links and establish a hierarchical relationship among movies based on the `movie_link` table. The main select aggregates actor information, including total movies they starred in, the names of the companies involved in producing those movies, while filtering specifically for actors whose names contain 'Smith'. It ensures to return only actors who have played in more than 5 movies, and results are ordered by the number of movies in descending order.
