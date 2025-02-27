WITH RecursiveActor AS (
    SELECT c.person_id, 
           COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info AS ci
    JOIN aka_name AS ak ON ci.person_id = ak.person_id
    WHERE ak.name IS NOT NULL
    GROUP BY c.person_id
),
RankedActors AS (
    SELECT ra.person_id,
           ra.movie_count,
           DENSE_RANK() OVER (ORDER BY ra.movie_count DESC) AS actor_rank
    FROM RecursiveActor AS ra
),
TopActors AS (
    SELECT person_id
    FROM RankedActors
    WHERE actor_rank <= 10
),
MovieDetails AS (
    SELECT t.id AS movie_id, 
           t.title, 
           t.production_year,
           COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No Cast') AS actor_names
    FROM aka_title AS t
    LEFT JOIN cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN aka_name AS ak ON ci.person_id = ak.person_id
    GROUP BY t.id, t.title, t.production_year
)
SELECT md.movie_id, 
       md.title, 
       md.production_year, 
       md.actor_names, 
       (CASE 
           WHEN md.production_year IS NULL THEN 'Unknown Year' 
           ELSE CAST(md.production_year AS TEXT) 
        END) AS production_year_text,
       (SELECT COUNT(*)
        FROM movie_info AS mi
        WHERE mi.movie_id = md.movie_id
          AND EXISTS (SELECT 1 FROM info_type WHERE id = mi.info_type_id AND info = 'rating')) AS rating_info_count,
       (SELECT COUNT(*)
        FROM movie_keyword AS mk
        WHERE mk.movie_id = md.movie_id) AS keyword_count,
       (SELECT ARRAY_AGG(kt.keyword)
        FROM movie_keyword AS mk
        JOIN keyword AS kt ON mk.keyword_id = kt.id
        WHERE mk.movie_id = md.movie_id) AS movie_keywords
FROM MovieDetails AS md
WHERE EXISTS (SELECT 1 
              FROM TopActors AS ta 
              JOIN cast_info AS ci ON ci.person_id = ta.person_id
              WHERE ci.movie_id = md.movie_id)
ORDER BY md.production_year DESC NULLS LAST, 
         md.title ASC;

This SQL query showcases a complex structure that utilizes Common Table Expressions (CTEs) to break down the task into manageable parts. It incorporates window functions for ranking actors based on the number of movies, string aggregation for actor names, conditional logic for handling NULL values, and correlated subqueries to gather additional information about ratings and keywords associated with the movies.

### Breakdown of the Query:

1. **RecursiveActor CTE**: 
   - Counts the number of distinct movies associated with each actor.

2. **RankedActors CTE**: 
   - Ranks the actors based on the number of movies they have acted in.

3. **TopActors CTE**: 
   - Filters down to the top 10 actors based on their ranks.

4. **MovieDetails CTE**: 
   - Gathers movie details including title, production year, and an aggregation of all actor names associated with each movie.

5. **Final SELECT**: 
   - The main query selects movies that have been acted in by the top actors, along with their additional details and counts of specific information fields such as ratings and keywords.

6. **Using CASE**: 
   - A CASE statement handles the potential NULL values in production year for clean output.

This query utilizes various SQL constructs effectively while handling corner cases and potential NULL logic in an interesting and engaging way.
