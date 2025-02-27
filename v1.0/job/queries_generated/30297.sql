WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.path || m.id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    aka.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    ARRAY_AGG(DISTINCT c.role_id) AS role_ids,
    COUNT(DISTINCT h.movie_id) AS episodes_count,
    ROW_NUMBER() OVER (PARTITION BY aka.id ORDER BY mt.production_year DESC) AS role_rank
FROM 
    aka_name aka
JOIN 
    cast_info c ON aka.person_id = c.person_id
JOIN 
    aka_title mt ON c.movie_id = mt.id
LEFT JOIN 
    movie_hierarchy h ON mt.id = h.movie_id
WHERE 
    mt.production_year >= 2000
    AND aka.name IS NOT NULL
GROUP BY 
    aka.id, mt.id, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT c.role_id) > 1
ORDER BY 
    role_rank, movie_title;

### Explanation of Query Components:

1. **CTE (`WITH RECURSIVE movie_hierarchy`)**: 
   - This recursive CTE constructs a hierarchy of movies based on episode relationships, pulling movies that serve as a series' base (no `episode_of_id`) and subsequently joining to linked movies.

2. **Main Query**: 
   - It gathers actor names from `aka_name`, joined with their respective roles in movies (`cast_info`).
   - It fetches movie details from `aka_title` based on the joined data.

3. **LEFT JOIN**: 
   - Utilizes the hierarchical CTE to count how many episodes are associated with each movie, allowing for a comprehensive view of multi-episode contributions by the actors.

4. **WHERE Clause**: 
   - Filters movies produced from the year 2000 onwards and excludes any `NULL` names from the results.

5. **GROUP BY with Aggregations**: 
   - Groups results by actor and each movie to extract unique role IDs with `ARRAY_AGG` and counts episodes per actor through `COUNT(DISTINCT ...)`.

6. **HAVING Clause**: 
   - Ensures only those actors who played multiple roles are included in the final results.

7. **Window Function (`ROW_NUMBER()`)**: 
   - Assigns a role ranking based on the production year of movies, showing the most recent roles first.

8. **Final Output**: 
   - Orders the results by role rank and movie title for easier reading.

This query effectively benchmarks the schema in various dimensions, utilizing both hierarchical and flat relationships while demonstrating complex SQL capability with proper use of aggregation, filtering, and logical structuring.
