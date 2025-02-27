WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::INTEGER AS parent_movie_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id IS NOT NULL 

    UNION ALL 

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(a.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    SUM(CASE 
        WHEN mc.company_id IS NOT NULL THEN 1 
        ELSE 0 
    END) AS company_count,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY a.name) AS actor_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, a.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 3 AND 
    SUM(CASE WHEN mc.company_type_id IS NULL THEN 1 ELSE 0 END) = 0
ORDER BY 
    mh.production_year DESC, mh.level ASC;

This query does the following steps:

1. Creates a recursive common table expression (CTE) named `movie_hierarchy` that generates a hierarchy of movies based on their links.

2. Selects movie information from the hierarchy created, including the `movie_id`, `title`, `production_year`, and the recursion level.

3. Joins with `cast_info` and `aka_name` to retrieve actor names, allowing for cases where no actor is found (using `COALESCE`).

4. Includes a conditional aggregation with `COUNT` to count distinct keywords associated with each movie.

5. Sums up movie companies without a specified type.

6. Uses `HAVING` to filter results for movies with more than three actors and where there are no movie companies with NULL `company_type_id`.

7. Applies a window function `ROW_NUMBER()` to rank actors for each movie based on their names.

8. Orders results first by `production_year` in descending order and then by `level` in ascending order.
