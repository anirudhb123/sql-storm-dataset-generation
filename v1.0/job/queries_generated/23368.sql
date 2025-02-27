WITH RECURSIVE movie_hierarchy AS (
    SELECT t.id AS movie_id, 
           t.title, 
           t.production_year, 
           t.kind_id, 
           CAST(NULL AS INTEGER) AS parent_id
      FROM aka_title t
     WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT t.id, 
           t.title, 
           t.production_year, 
           t.kind_id, 
           h.movie_id
      FROM aka_title t
      JOIN movie_hierarchy h ON t.episode_of_id = h.movie_id
),
ranked_cast AS (
    SELECT c.movie_id,
           a.name AS actor_name,
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order,
           COUNT(*) OVER (PARTITION BY c.movie_id) AS total_cast
      FROM cast_info c
      JOIN aka_name a ON c.person_id = a.person_id
     WHERE a.name IS NOT NULL
),
aggregate_info AS (
    SELECT m.movie_id,
           COUNT(DISTINCT c.person_id) AS unique_actors,
           STRING_AGG(DISTINCT a.actor_name, ', ') AS all_actors,
           MAX(m.production_year) AS last_produced_year
      FROM movie_hierarchy m
      LEFT JOIN cast_info c ON m.movie_id = c.movie_id
      LEFT JOIN aka_name a ON c.person_id = a.person_id AND a.name IS NOT NULL
     GROUP BY m.movie_id
)
SELECT h.movie_id,
       h.title,
       h.production_year,
       h.kind_id,
       COALESCE(ai.unique_actors, 0) AS unique_actors_count,
       ai.all_actors,
       CASE 
           WHEN ai.last_produced_year IS NOT NULL 
           THEN 'Produced after ' || (ai.last_produced_year - 5) || ' years ago'
           ELSE 'Production year unknown'
       END AS production_status,
       RANK() OVER (ORDER BY ai.unique_actors DESC) AS actor_ranking
  FROM movie_hierarchy h
  LEFT JOIN aggregate_info ai ON h.movie_id = ai.movie_id
 WHERE h.production_year > 2000
   AND (h.kind_id, COALESCE(ai.unique_actors, 0)) NOT IN (
        SELECT kind_id, unique_actors FROM aggregate_info WHERE unique_actors < 5
   )
ORDER BY actor_ranking, h.production_year DESC
LIMIT 50 OFFSET 10;

### Explanation:

1. **Recursive CTE (`movie_hierarchy`)**: This common table expression constructs a hierarchy of movies and episodes, where episodes are linked to their parent movies.
  
2. **Ranked Cast (`ranked_cast`)**: This CTE ranks actors in each movie in order of appearance and computes the total number of actors per movie.

3. **Aggregate Info (`aggregate_info`)**: This CTE aggregates information for each movie, gathering unique actor counts, a concatenated list of actor names, and the last production year.

4. **Final Selection**: The final query selects from the hierarchy of movies, joining with `aggregate_info` to access calculated fields. It pulls in the title, production year, counts, and a production status message dependent on the production year.

5. **Complicated Filtering**: The `WHERE` clause adds complex filters on production years and excludes kinds of movies with fewer than 5 unique actors.

6. **Sorting and Limits**: The results are finally ordered by actor ranking and production year, along with pagination via `LIMIT` and `OFFSET`. 

This query emphasizes various SQL constructs, including CTEs, window functions, and advanced filtering with NULL logic, making it suitable for performance benchmarking on join operations and complex aggregations.
