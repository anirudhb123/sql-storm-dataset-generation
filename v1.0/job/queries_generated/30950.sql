WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        1 AS depth
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
      AND t.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        c.person_id,
        a.name,
        t.title,
        t.production_year,
        ah.depth + 1
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    JOIN ActorHierarchy ah ON ah.person_id = c.person_id
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
      AND t.production_year < 2000
)

SELECT 
    ah.actor_name,
    COUNT(DISTINCT ah.movie_title) AS total_movies,
    MAX(ah.production_year) AS last_movie_year,
    MIN(ah.production_year) AS first_movie_year,
    CASE 
        WHEN MAX(ah.production_year) IS NULL THEN 'N/A'
        ELSE CAST(EXTRACT(YEAR FROM AGE(MAX(ah.production_year))) AS INTEGER) || ' years'
    END AS years_since_last_movie,
    STRING_AGG(DISTINCT ah.movie_title || ' (' || ah.production_year || ')', ', ') AS movie_list,
    RANK() OVER (ORDER BY COUNT(DISTINCT ah.movie_title) DESC) AS movie_rank
FROM ActorHierarchy ah
GROUP BY ah.actor_name
HAVING COUNT(DISTINCT ah.movie_title) > 5
ORDER BY movie_rank, ah.actor_name;

### Explanation of the Query:
1. **Recursive CTE `ActorHierarchy`**:
    - This common table expression recursively pulls in actors and their respective movies, starting from movies produced after 2000.
    - It continues to pull movies made before 2000 for the same actors, allowing for a depth level for hierarchy tracking.

2. **Main SELECT Statement**:
    - This part aggregates the derived results from the recursive CTE:
        - `COUNT(DISTINCT ah.movie_title)` gives the total number of distinct movies the actor has appeared in.
        - `MAX(ah.production_year)` and `MIN(ah.production_year)` find the most recent and oldest movie, respectively.
        - A `CASE` statement calculates how many years it has been since the last film, defaulting to 'N/A' if no movies are found.
        - `STRING_AGG` concatenates the list of movies and their years into a readable format.
        - `RANK()` assigns a rank based on the number of movies.

3. **Filtering and Ordering**:
    - The `HAVING` clause filters to include only actors who have been in more than 5 movies.
    - Finally, results are ordered by the number of movies in descending order and actor names alphabetically.
