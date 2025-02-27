WITH RECURSIVE MovieHierarchy AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           t.kind_id,
           0 AS hierarchy_level,
           t.id AS root_movie_id
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
    UNION ALL
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           t.kind_id,
           mh.hierarchy_level + 1,
           mh.root_movie_id
    FROM aka_title t
    JOIN movie_link ml ON t.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.hierarchy_level < 5
)
, CastDetails AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS actor_count,
           COUNT(DISTINCT ci.person_role_id) AS role_count,
           SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
DetailedMovies AS (
    SELECT mh.movie_id,
           mh.title,
           mh.production_year,
           kt.kind AS genre,
           cd.actor_count,
           cd.role_count,
           cd.note_count,
           ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cd.actor_count DESC) AS rank_per_year
    FROM MovieHierarchy mh
    LEFT JOIN kind_type kt ON mh.kind_id = kt.id
    LEFT JOIN CastDetails cd ON mh.movie_id = cd.movie_id
)
SELECT d.title,
       d.production_year,
       d.genre,
       d.actor_count,
       d.role_count,
       d.note_count,
       CASE 
           WHEN d.actor_count IS NULL THEN 'No actors'
           WHEN d.actor_count > 10 THEN 'Blockbuster'
           WHEN d.actor_count BETWEEN 1 AND 10 THEN 'Indie Film'
           ELSE 'Uncredited'
       END AS film_type,
       COALESCE(d.note_count, 0) AS actual_notes,
       FIRST_VALUE(d.title) OVER (PARTITION BY d.production_year ORDER BY d.actor_count DESC) AS top_film_current_year
FROM DetailedMovies d
WHERE (d.production_year > 2000 AND d.actor_count IS NOT NULL)
   OR (d.production_year <= 2000 AND d.role_count IS NULL)
ORDER BY d.production_year, d.actor_count DESC
LIMIT 100;

### Explanation of SQL Query:
1. **CTE - MovieHierarchy**: A recursive CTE is established to create a hierarchy of movies, linking each movie with any associated movies up to 5 levels. It also ensures that only movies with a production year are included.

2. **CTE - CastDetails**: This CTE computes statistics related to the cast, such as the count of different actors, different roles, and how many notes are present.

3. **CTE - DetailedMovies**: Here, movie details are combined with the genre from the `kind_type` table and actor statistics from the `CastDetails` CTE. A window function (`ROW_NUMBER()`) ranks the films within their production year based on the actor count.

4. **Main Query Selection**:
   - Selects relevant movie details and computes a film type based on the number of actors:
     - Identifies movies as "Blockbuster," "Indie Film," or "Uncredited" based on conditions.
     - Uses `COALESCE` to handle possible nulls in the notes count.
     - `FIRST_VALUE` fetches the title of the top film for the year.

5. **WHERE Clause Logic**: The condition filters movies based on their production year and whether they have associated actor information.

6. **Final ORDER BY and LIMIT**: Results are ordered by production year and the count of actors, limiting the output to the top 100 records, making it feasible for performance benchmarking.

This query incorporates many sophisticated SQL features, including CTEs, window functions, complex conditional logic, null checks, and outer joins, making it intriguing for performance analysis and testing.
