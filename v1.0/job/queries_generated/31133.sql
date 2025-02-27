WITH RECURSIVE ActorHierarchy AS (
    SELECT c.person_id, 
           a.name AS actor_name, 
           t.title AS movie_title,
           1 AS level
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT c.person_id, 
           a.name AS actor_name, 
           t.title AS movie_title,
           ah.level + 1
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    JOIN ActorHierarchy ah ON c.movie_id = ah.movie_id
)
SELECT 
    a.actor_name,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(t.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
    MAX(ah.level) AS depth_of_collaboration
FROM ActorHierarchy ah
JOIN aka_name a ON ah.person_id = a.person_id
JOIN aka_title t ON ah.movie_title = t.title
LEFT JOIN movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office' LIMIT 1)
WHERE mi.info IS NULL OR mi.info::numeric > 5000000
GROUP BY a.actor_name
HAVING COUNT(DISTINCT t.id) > 5
ORDER BY movie_count DESC, avg_production_year DESC
LIMIT 10;

### Explanation of the Query Constructs:
1. **Recursive CTE (Common Table Expression)** (`ActorHierarchy`): This finds all actors and builds a hierarchy of movies they have participated in, allowing for levels of collaboration to be tracked.

2. **Joins**:
   - Joins between the `cast_info`, `aka_name`, and `aka_title` to fetch actor names and corresponding movie titles.
   - A left join with `movie_info` ensures we can aggregate information without affecting the movie count, especially for movies with missing box office information.

3. **Aggregate Functions**:
   - `COUNT(DISTINCT t.id)`: Counts the unique movies per actor.
   - `AVG(t.production_year)`: Averages the production year of movies.
   - `STRING_AGG(DISTINCT t.title, ', ')`: Concatenates unique movie titles into a single string.

4. **Subquery**: Used to dynamically fetch the `id` of the info type related to box office earnings, enhancing the query's flexibility.

5. **Filters and Conditions**:
   - Checks for `NULL` or box office earnings greater than `5000000`.
   - Uses a `HAVING` clause to ensure only actors with more than 5 movies are considered.

6. **Ordering and Limiting**:
   - Results are ordered by the number of movies (in descending order) and then by average production year.
   - The results are limited to the top 10 actors, making the output manageable.

This SQL query is designed not only to benchmark performance through complex structures but also to provide valuable insights into actor collaborations and movie success metrics.
