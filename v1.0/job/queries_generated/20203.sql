WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        ARRAY[mt.production_year] AS production_years,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.production_years || at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year IS NOT NULL
)

SELECT 
    a.name AS actor_name,
    ARRAY_AGG(DISTINCT mh.title) AS linked_movies,
    COUNT(DISTINCT mh.movie_id) AS total_linked_movies,
    STRING_AGG(DISTINCT COALESCE(k.keyword, 'Unknown'), ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    movie_keyword mk ON mc.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
WHERE 
    a.name IS NOT NULL
    AND a.name <> ''
    AND ci.nr_order IS NOT NULL
    AND (k.keyword IS NULL OR LENGTH(k.keyword) > 3)
GROUP BY 
    a.id, a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    total_linked_movies DESC,
    actor_name
LIMIT 10;


### Explanation of the SQL query:

- **CTE (Common Table Expression)**: A recursive CTE named `movie_hierarchy` is created to traverse the links between movies. It starts with movies that have a production year and recursively joins on the `movie_link` table to aggregate movies linked in a chain while collecting all production years into an array.

- **Main SELECT Query**: The main query fetches actor names from the `aka_name` table and joins it with `cast_info`, `movie_companies`, and `movie_keyword`. It gets distinct movie titles from the hierarchy CTE.

- **Array Aggregation**: The query uses `ARRAY_AGG` to collect all unique linked movie titles into an array for each actor.

- **Conditional Keyword Logic**: Using `LEFT JOIN`, it fetches keywords associated with the movies and replaces NULLs with 'Unknown', collecting them into a string using `STRING_AGG`.

- **Complicated Conditions**: The query filters actors based on the following:
    - Their name must not be NULL or empty.
    - Only cast orders that are not NULL.
    - Keywords must either be NULL or have a length greater than 3 characters.

- **Aggregation and Ordering**: The results are grouped by actor ID and name, filtered to show only actors linked to more than 5 movies, and ordered by the total number of linked movies in descending order.

- **Limit**: Finally, the result is limited to the top 10 results based on the specified order.

This query effectively combines various SQL constructs and complexities, designed to benchmark performance with nested joins, recursive logic, and aggregation functions.
