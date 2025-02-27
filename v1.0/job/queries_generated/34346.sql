WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    INNER JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mk.movie_id) AS movies_count,
    string_agg(DISTINCT mt.movie_title, ', ') AS movie_titles,
    MAX(mh.depth) AS max_depth,
    AVG(mh.production_year) AS avg_year
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    movie_hierarchy mh ON mk.movie_id = mh.movie_id
LEFT JOIN 
    aka_title mt ON mk.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL AND
    ak.name <> ''
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mk.movie_id) > 5
ORDER BY 
    movies_count DESC, 
    actor_name ASC;

This query does the following:

1. It begins with a recursive Common Table Expression (CTE) called `movie_hierarchy` that constructs a hierarchy of linked movies starting from movies produced after the year 2000.
2. It collects the names of actors alongside the count of distinct movies they are associated with, using `COUNT(DISTINCT mk.movie_id)`.
3. The `string_agg` function is used to concatenate the titles of the movies into a single string for each actor.
4. It calculates the maximum link depth of the movies and the average production year.
5. There’s conditional logic in the `WHERE` clause to filter out records where actor names are NULL or empty.
6. The result is grouped by actor's name, and only actors with more than 5 distinct movies are retained due to the `HAVING` clause.
7. Finally, it orders the results by the count of movies descending and actor names in ascending order.
