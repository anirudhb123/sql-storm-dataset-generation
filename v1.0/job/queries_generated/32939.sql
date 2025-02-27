WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id = 1  -- Assuming '1' represents movies

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title AS mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_role_order,
    STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
FROM 
    aka_name AS ak
JOIN 
    cast_info AS c ON ak.person_id = c.person_id
JOIN 
    aka_title AS at ON c.movie_id = at.id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = at.id
LEFT JOIN 
    keyword AS kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_hierarchy AS mh ON mh.movie_id = at.id
WHERE 
    ak.name IS NOT NULL
    AND at.production_year >= 2000
GROUP BY 
    ak.name, at.title
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC, avg_role_order ASC;

### Explanation:
1. **Recursive CTE (`movie_hierarchy`)**: This creates a hierarchy of movies based on their links, allowing us to explore not only direct movies but also linked ones, potentially serial works.
  
2. **Main Query**:
   - Selects the actor names and movie titles, counting the distinct movies for each actor.
   - Calculates the average role order the actors appear in.
   - Aggregates the keywords associated with each movie using `STRING_AGG`.
   - Ranks actors based on the total number of movies they have appeared in.

3. **Joins**: 
   - Joins `aka_name`, `cast_info`, and `aka_title` to gather necessary actor and movie details.
   - Uses a left join with `movie_keyword` and `keyword` to collect keyword information associated with each movie.

4. **Filters and Grouping**: 
   - Filters out movies produced before 2000 and ensures only actors appearing in more than five movies are included.
   - Sorting is done by total movies descending and then by average role order ascending.

This query would help in benchmarking actor performance over time while offering insights into linked movie relationships, role prominence, and associated keywords.
