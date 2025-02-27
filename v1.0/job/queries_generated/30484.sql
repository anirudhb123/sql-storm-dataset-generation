WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        c.nr_order,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id = (SELECT MIN(movie_id) FROM cast_info)  -- Base case: starting from the movie with the minimum ID

    UNION ALL

    SELECT 
        c.person_id,
        a.name AS actor_name,
        c.nr_order,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.movie_id  -- Recursive case: getting associated actors
)

SELECT 
    mv.title,
    mv.production_year,
    COUNT(DISTINCT ac.actor_name) AS actor_count,
    STRING_AGG(DISTINCT ac.actor_name, ', ') AS actor_names,
    COUNT(DISTINCT ni.info) FILTER (WHERE ni.info_type_id = 1) AS genre_count,  -- Assuming 1 is for genre
    SUM(CASE WHEN tc.kind IS NOT NULL THEN 1 ELSE 0 END) AS type_count,
    COALESCE(cn.name, 'Unknown') AS company_name
FROM 
    title mv
LEFT JOIN 
    movie_info ni ON mv.id = ni.movie_id
LEFT JOIN 
    movie_companies mc ON mv.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    ActorHierarchy ac ON mv.id = ac.movie_id
LEFT JOIN 
    movie_keyword mk ON mv.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    kind_type tc ON mv.kind_id = tc.id
GROUP BY 
    mv.id, mv.title, mv.production_year, cn.name
HAVING 
    COUNT(DISTINCT ac.actor_name) > 0
ORDER BY 
    actor_count DESC, mv.production_year ASC
LIMIT 10;

### Explanation of the Query:

1. **Recursive CTE (`ActorHierarchy`)**: This CTE recursively finds all actors associated with movies, starting from the movie with the lowest movie_id, allowing for the construction of a hierarchy.

2. **Main Query**: The query retrieves details about movies:
   - It selects movie titles and production years.
   - It counts distinct actors linked to each movie.
   - It concatenates actor names into a single string.
   - It counts the number of distinct genres (assuming `info_type_id = 1` is for genre).
   - It sums the count of associated company types for each movie.
   - It uses `COALESCE` to assign a default value if company names are NULL.
   
3. **Grouping and Ordering**: The results are grouped by movie details and sorted by actor count and production year.

4. **Filtering**: It ensures that only movies with at least one actor are included in the results, applying the `HAVING` clause accordingly.

5. **Limiting Results**: Finally, it limits the output to the top 10 results based on these criteria.
