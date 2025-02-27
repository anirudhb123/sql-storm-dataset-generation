WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.kind_id = 1 -- Assuming kind_id = 1 represents movies

    UNION ALL

    SELECT m.id AS movie_id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorStats AS (
    SELECT
        a.name AS actor_name,
        COUNT(c.movie_id) AS movie_count,
        SUM(CASE WHEN c.nr_order IS NULL THEN 0 ELSE 1 END) AS principal_roles,
        AVG(COALESCE(t.production_year, 0)) AS avg_production_year
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    LEFT JOIN aka_title t ON c.movie_id = t.id
    GROUP BY a.name
),
TopActors AS (
    SELECT actor_name, movie_count, principal_roles, avg_production_year,
           ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS rank
    FROM ActorStats
    WHERE movie_count > (
        SELECT AVG(movie_count) FROM ActorStats
    )
)
SELECT 
    ma.movie_id,
    ma.title,
    ma.production_year,
    ta.actor_name,
    ta.movie_count,
    ta.principal_roles,
    COALESCE(ta.avg_production_year, 'N/A') AS avg_production_year
FROM MovieHierarchy ma
LEFT JOIN TopActors ta ON ma.movie_id IN (
    SELECT c.movie_id 
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name = ta.actor_name
)
ORDER BY ma.production_year DESC, ta.principal_roles DESC NULLS LAST
LIMIT 100;


This SQL query consists of multiple constructs and demonstrates complex relationships likely found in a movie database. Here's a breakdown of its elements:

1. **Common Table Expressions (CTEs)**: 
   - `MovieHierarchy` collects movies as a hierarchy based on some kind of linked movie relationship.
   - `ActorStats` computes statistics for actors, including the number of movies they appeared in and an average production year.
   - `TopActors` filters the `ActorStats` to include only those actors who appeared in more than average movies, with ranking included.

2. **Correlated Subqueries**: 
   - There are correlated subqueries to link movie IDs back to the actor, based on their appearances.

3. **Window Functions**: 
   - The `ROW_NUMBER()` function in `TopActors` gives a ranking to actors based on their movie counts.

4. **COALESCE and NULL Logic**:
   - It uses `COALESCE` to handle potential null values in average production year gracefully.

5. **Outer Joins**: 
   - The main selection employs a `LEFT JOIN`, which means even movies with no associated actors will still show up in the results.

6. **Complex Filtering and Ordering**: 
   - Movies are sorted by production year and by the number of principal roles, using unusual ordering logic to handle NULLs.

7. **Limit**: 
   - The result set is capped at 100 rows, keeping the output manageable.

This query is well-suited for performance benchmarking due to its combination of complex joins, filtering, and ordered results.
