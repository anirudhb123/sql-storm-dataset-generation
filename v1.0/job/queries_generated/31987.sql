WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        1 AS level,
        mt.title,
        mt.production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Start from top-level movies

    UNION ALL

    SELECT 
        at.id AS movie_id,
        mh.level + 1 AS level,
        at.title,
        at.production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title at
    JOIN 
        movie_hierarchy mh ON at.episode_of_id = mh.movie_id  -- Join to find episodes
)

SELECT 
    r.role,
    p.name AS actor_name,
    count(DISTINCT ch.movie_id) AS movies_count,
    AVG(YEAR(CURRENT_DATE) - ch.production_year) AS avg_movie_age,
    string_agg(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    aka_name p ON ci.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    mt.production_year >= 2000 AND 
    (p.name IS NOT NULL OR p.name <> '')  -- Ensure name is not NULL or empty
GROUP BY 
    p.name, r.role
HAVING 
    count(DISTINCT ch.movie_id) > 5  -- Actors with more than 5 movies
ORDER BY 
    avg_movie_age DESC, movies_count DESC;

### Explanation:
1. **Recursive CTE (`movie_hierarchy`)**: This retrieves a hierarchical structure of movies and episodes, starting from top-level movies without episodes.
  
2. **Main Query**: 
   - Joins the recursive CTE to the `complete_cast`, `cast_info`, `role_type`, and `aka_name` tables to get required details about actors, their roles, and associated movies.
   - Uses a `LEFT JOIN` with `movie_keyword` to pull relevant keywords for each movie.
  
3. **Filters**:
   - Products of movies from the year 2000 onwards.
   - Ensures that actor names are not NULL or empty.
  
4. **Aggregation**:
   - Counts the distinct movies per actor, evaluates the average age of movies each actor has participated in, and aggregates keywords into a comma-separated string.
  
5. **Grouping and Having**:
   - Groups results by actor names and roles.
   - Filters to include only those with more than 5 distinct movies.
  
6. **Ordering**:
   - Ordered by average movie age descending first, followed by the count of movies descending to highlight actors involved in older films substantially. 

This query showcases various SQL features, including recursive CTEs, joins, aggregations, filtering, and ordering for performance benchmarking in a complex dataset.
