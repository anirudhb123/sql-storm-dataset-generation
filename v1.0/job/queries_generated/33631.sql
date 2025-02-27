WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movies_count,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
    COALESCE(SUM(CASE WHEN ci.role_id = 1 THEN 1 ELSE 0 END), 0) AS actor_roles,
    COALESCE(SUM(CASE WHEN ci.role_id = 2 THEN 1 ELSE 0 END), 0) AS director_roles,
    AVG(CASE 
            WHEN t.production_year IS NOT NULL 
            THEN EXTRACT(YEAR FROM now()) - t.production_year 
            ELSE NULL 
        END) AS avg_years_since_release,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%box office%')
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = t.id
WHERE 
    a.name IS NOT NULL
    AND (t.production_year > 2000 OR t.production_year IS NULL)
GROUP BY 
    a.id
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    actor_rank;

### Explanation:
1. **Recursive CTE (movie_hierarchy)**: The `WITH RECURSIVE` clause begins by selecting movies produced from the year 2000 onwards. The recursive part connects these movies to their linked movies, allowing for a hierarchy generation.
   
2. **Main Query**: It selects the actor's name, counts distinct movies they appeared in, aggregates the movie titles into a string, and conditionally sums up roles using COALESCE to handle NULL values.

3. **Window Function**: `ROW_NUMBER()` is used to rank actors based on the count of distinct movies they were involved in.

4. **Complex conditions**: Conditions ensure proper handling of NULL values and apply logic to filter years and roles appropriately.

5. **Grouping and Ordering**: The results are grouped by actor ID, filtered by a minimum count of 5 movies, and ordered by their rank. 

This query incorporates various SQL constructs making it suitable for performance benchmarking in a complex database schema.
