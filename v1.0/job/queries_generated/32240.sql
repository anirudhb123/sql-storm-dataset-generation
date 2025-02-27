WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(ca.name, 'Unknown') AS actor_name,
        COALESCE(c.type, 'Unknown') AS company_type,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        m.production_year >= 2000
    
    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        COALESCE(ca.name, 'Unknown') AS actor_name,
        COALESCE(c.type, 'Unknown') AS company_type,
        level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        mh.level < 5
)

SELECT 
    movie_id,
    title,
    COUNT(DISTINCT actor_name) AS total_actors,
    STRING_AGG(DISTINCT actor_name, ', ') AS actor_list,
    COUNT(DISTINCT company_type) AS total_company_types,
    MAX(level) AS max_level 
FROM 
    movie_hierarchy
GROUP BY 
    movie_id, title
HAVING 
    COUNT(DISTINCT actor_name) > 2
ORDER BY 
    total_actors DESC, title ASC
WITH ROLLUP;

### Explanation:

1. **Recursive CTE (`WITH RECURSIVE`)**: The CTE generates a hierarchy of movies along with their actors and companies by recursively linking movies through the `movie_link` table.

2. **Outer Joins**: `LEFT JOIN` is used to include records even if there are no matching entries in the related tables.

3. **Aggregation**: The main query aggregates data on the movie level, counting distinct actors and companies, and listing their names.

4. **String Aggregation**: `STRING_AGG` is used to gather all actor names associated with a movie into a single string.

5. **Count and Group**: The `HAVING` clause filters results to only show movies with more than 2 distinct actors.

6. **Ordering**: The results are ordered first by the number of actors and then by movie title.

7. **Rollup**: The `WITH ROLLUP` syntax provides subtotals in the final output.

This query aims to give insights into movies since 2000, showing those with a rich cast and diverse production companies.
