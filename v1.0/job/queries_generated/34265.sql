WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title linked ON linked.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = m.id
    WHERE 
        mh.level < 3  -- Limit the hierarchy depth
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    COALESCE(k.keyword, 'No Keyword') AS movie_keyword,
    YEAR(mh.production_year) AS production_year,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(CASE WHEN mc.company_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_companies_per_movie
FROM 
    cast_info c
JOIN 
    aka_name a ON a.person_id = c.person_id
JOIN 
    movie_info mi ON mi.movie_id = c.movie_id
JOIN 
    aka_title t ON t.id = c.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = c.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = c.movie_id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = c.movie_id
GROUP BY 
    a.name, t.title, k.keyword, mh.production_year
HAVING 
    COUNT(DISTINCT c.movie_id) > 1
ORDER BY 
    production_year DESC,
    total_movies DESC;

### Explanation:
1. **Recursive CTE (`movie_hierarchy`)**: This builds a hierarchy of movies by linking them via `movie_link`, allowing to explore connections between films up to a depth of 3 levels.

2. **Main Query**: 
   - Utilizes multiple `JOIN`s to link `cast_info`, `aka_name`, `movie_info`, and `aka_title`.
   - Uses `LEFT JOINs` to include all movies even if they don't have associated keywords or companies.
   - `COALESCE` is used to handle potential `NULL` values for keywords.
  
3. **Aggregations**: 
   - Uses `COUNT` to get the distinct movie counts for each actor.
   - Applies `AVG` to calculate the average number of companies associated with each movie.

4. **Group and Filter**: 
   - The `GROUP BY` clause organizes results by actor name, movie title, keyword, and production year.
   - The `HAVING` clause filters for actors who have appeared in more than one movie.

5. **Ordering**: Results are sorted by `production_year` descending and `total_movies` descending, focusing on recent activity. 

This complex query illustrates the relationships and connections in the movie data schema while applying various SQL constructs.
