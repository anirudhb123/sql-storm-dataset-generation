WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        linked.linked_movie_id AS movie_id,
        linked.title,
        linked.production_year,
        h.depth + 1
    FROM 
        MovieHierarchy h
    JOIN 
        movie_link ml ON h.movie_id = ml.movie_id
    JOIN 
        aka_title linked ON ml.linked_movie_id = linked.id
    WHERE 
        h.depth < 5 
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    STRING_AGG(DISTINCT mh.title, ', ') AS linked_movies,
    AVG(m.production_year) AS avg_production_year,
    MAX(mh.depth) AS max_depth
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
JOIN 
    MovieHierarchy mh ON cc.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id 
WHERE 
    a.name IS NOT NULL 
    AND a.name NOT LIKE '%test%'
    AND a.id IS NOT NULL 
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 1 
ORDER BY 
    movie_count DESC, 
    actor_name
LIMIT 10;

### Explanation:
1. **CTE (Common Table Expression)**: The recursive CTE `MovieHierarchy` retrieves movies produced after the year 2000 and builds a hierarchy of movie links up to five levels deep.
2. **Joins**:
   - Joins `aka_name` with `cast_info` to get the names of the actors.
   - Joins with `complete_cast` to filter for movies those actors are involved in.
   - Additionally links to the `movie_companies` to gather company-related information.
3. **Aggregation**:
   - Counts distinct movies featuring an actor.
   - Uses `STRING_AGG` to concatenate linked movie titles.
   - Calculates the average production year of the movies.
4. **Filters**:
   - Excludes actors with NULL names or names containing 'test'.
   - Ensures to count only actors with contributions to multiple distinct movies.
5. **Ordering**: Results are sorted by the number of movies (descending) and actor name (ascending).
6. **Limit**: Restricts the output to the top 10 actors based on the number of distinct movies.
