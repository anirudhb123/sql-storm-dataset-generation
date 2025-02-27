WITH RECURSIVE ActorHierarchy AS (
    SELECT c.person_id, 
           a.name AS actor_name, 
           1 AS level
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)
        
    UNION ALL

    SELECT c.person_id, 
           a.name AS actor_name, 
           ah.level + 1
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN ActorHierarchy ah ON c.movie_id IN (SELECT id FROM complete_cast WHERE subject_id = ah.person_id)
)
SELECT 
    actor.actor_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    AVG(t.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT CASE WHEN ci.kind_id IS NULL THEN 1 END) AS null_kind_count,
    RANK() OVER (ORDER BY COUNT(DISTINCT mc.movie_id) DESC) AS actor_rank
FROM ActorHierarchy actor
LEFT JOIN movie_companies mc ON mc.movie_id IN (SELECT movie_id FROM complete_cast WHERE subject_id = actor.person_id)
LEFT JOIN movie_keyword mk ON mk.movie_id = mc.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN aka_title t ON t.id = mc.movie_id
LEFT JOIN cast_info ci ON ci.movie_id = mc.movie_id AND ci.person_id = actor.person_id
GROUP BY actor.actor_name
HAVING COUNT(DISTINCT mc.movie_id) > 5
ORDER BY actor_rank, total_movies DESC;

### Explanation:

1. **Recursive CTE (`ActorHierarchy`)**: 
   - Constructs a hierarchy of actors who have worked in movies since 2000. The recursion helps trace back to the original actor's contribution to movies they're involved with.

2. **Joins**: 
   - Joins `cast_info` with `aka_name` to get actor names, then joins to `movie_companies`, `movie_keyword`, and `aka_title` to gather movie-related data.

3. **Aggregations**:
   - `COUNT(DISTINCT mc.movie_id)` counts distinct movies an actor has appeared in.
   - `AVG(t.production_year)` finds the average production year of the movies they've been in.
   - `STRING_AGG(DISTINCT k.keyword, ', ')` collects unique keywords associated with those movies.

4. **NULL Logic**: 
   - Uses `COUNT(DISTINCT CASE WHEN ci.kind_id IS NULL THEN 1 END)` to count the number of movies where the kind of role is not specified (i.e., NULL).

5. **Window Function**: 
   - `RANK()` assigns a rank to actors based on the total number of movies they have, allowing for sorting.

6. **HAVING Clause**: 
   - Filters the results to only include actors with more than 5 movies.

7. **Ordering**: 
   - Finally, results are ordered by rank and then by the total number of movies for better readability.

This query could serve as a performance benchmark for a complex join and data aggregation scenario in the given schema.
