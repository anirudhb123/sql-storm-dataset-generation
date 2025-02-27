WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ca.person_id,
        a.name AS actor_name,
        1 AS depth
    FROM cast_info ca
    JOIN aka_name a ON ca.person_id = a.person_id
    WHERE ca.movie_id IN (SELECT id FROM aka_title WHERE kind_id = (SELECT id FROM kind_type WHERE kind = 'movie'))
    
    UNION ALL
    
    SELECT 
        ca.person_id,
        a.name AS actor_name,
        ah.depth + 1
    FROM cast_info ca
    JOIN aka_name a ON ca.person_id = a.person_id
    JOIN actor_hierarchy ah ON ca.movie_id = ah.movie_id
)
SELECT 
    a.actor_name,
    COUNT(DISTINCT m.id) AS movie_count,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords_used,
    AVG(m.production_year) AS avg_production_year,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY m.id) AS cast_size,
    MAX(p.info) FILTER (WHERE i.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')) AS bio
FROM actor_hierarchy a
JOIN complete_cast cc ON a.movie_id = cc.movie_id
JOIN aka_title m ON cc.movie_id = m.id
LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN person_info p ON a.person_id = p.person_id
LEFT JOIN info_type i ON p.info_type_id = i.id
GROUP BY a.actor_name
ORDER BY movie_count DESC
LIMIT 10;

### Explanation:
1. **CTE (Recursive)**: The `actor_hierarchy` CTE builds a hierarchy of actors participating in films of a particular type (e.g., 'movie'). It recursively pulls actors from the `cast_info` table associated with each film.

2. **Main Query**: The main query aggregates data for each actor:
   - Counts the distinct movies an actor has been part of.
   - Uses `ARRAY_AGG` to collect all unique keywords associated with those movies.
   - Calculates the average production year of movies that the actor appeared in.
   - Uses a window function to count the size of the cast for each movie.
   - Retrieves a "bio" from the `person_info` table conditionally based on `info_type_id`.

3. **Joins**: Utilizes multiple joins including outer joins to link relevant data across multiple tables, ensuring even movies without keywords are included in the results.

4. **Filtering and Ordering**: The results are filtered to return only the top 10 actors by the number of movies they've acted in, which showcases the use of ORDER BY and LIMIT in SQL.

5. **NULL Logic**: The use of `LEFT JOIN` ensures that if there are no associated keywords or bios for an actor, it does not exclude them from the main results.

This query is designed to utilize various SQL constructs while exploring relationships among actors, their films, and associated metadata, making it suitable for performance benchmarking.
