WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Considering movies produced from 2000 onwards
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name as actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    avg(mh.production_year) AS avg_production_year,
    MAX(mh.depth) AS max_depth
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'short'))
    AND ci.nr_order IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    total_movies DESC
LIMIT 10;

### Explanation:
1. **Common Table Expression (CTE)**: A recursive CTE `movie_hierarchy` is used to build a hierarchy of movies based on linked movies, allowing us to analyze both direct and linked films produced after the year 2000.
  
2. **Aggregations**: The main query aggregates data to get totals and distinct counts of movies per actor.

3. **Joins**: It incorporates outer joins with the `aka_name` and `aka_title` to enrich actor names and movie information.

4. **Subquery**: Using a subquery to filter only specific movie kinds while ensuring movies are not duplicates.

5. **String Aggregation**: `STRING_AGG` function collects a list of movie titles associated with each actor.

6. **NULL Logic**: The condition for `nr_order IS NOT NULL` ensures only valid roles are considered.

7. **Complex Conditions**: The query applies filters on the counts in the `HAVING` clause to focus on prolific actors, and it orders them by the total count of movies descending, limiting the results to the top 10 actors. 

This approach enables a comprehensive performance benchmark based on intricate relationships and conditions within the movie database schema.
