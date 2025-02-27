WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        l.linked_movie_id, 
        t.title, 
        t.production_year, 
        mh.level + 1
    FROM 
        movie_link l
    INNER JOIN 
        title t ON l.linked_movie_id = t.id
    INNER JOIN 
        movie_hierarchy mh ON mh.movie_id = l.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COALESCE(GROUP_CONCAT(DISTINCT k.keyword), 'No Keywords') AS keywords,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order END) OVER (PARTITION BY a.id) AS avg_order,
    COUNT(DISTINCT c.id) AS total_cast
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    title t ON mh.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year IS NOT NULL
GROUP BY 
    a.id, t.title, t.production_year
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    avg_order DESC, 
    t.production_year ASC;

### Explanation:
1. **Recursive CTE**: The `movie_hierarchy` CTE retrieves a list of movies from the year 2000 onwards and recursively gathers linked movies to build a hierarchy.
2. **Main Query**: The main query gathers actor names and their associated movie details from the `aka_name`, `cast_info`, and the recursive CTE.
3. **Aggregations**:
   - `GROUP_CONCAT` is used to aggregate keywords into a single string, defaulting to 'No Keywords' if none exist.
   - The average order from the cast information is computed using a window function.
   - Count of the distinct cast members for each actor-movie combination is calculated.
4. **Filters**: The `HAVING` clause filters out actors who have participated in only one movie.
5. **Sorting**: Results are ordered by average casting order in descending order, then by movie production year in ascending order.

This query showcases advanced SQL concepts with complex joins and aggregations, while effectively utilizing CTEs, window functions, and aggregations.
