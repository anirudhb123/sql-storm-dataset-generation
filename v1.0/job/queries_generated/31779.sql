WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM title t
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link m
    JOIN title t ON m.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON m.movie_id = mh.movie_id
),

TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM MovieHierarchy mh
    JOIN complete_cast cc ON mh.movie_id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
    ORDER BY cast_count DESC
    LIMIT 10
),

ActorsWithAwards AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT a.id) AS awards_count
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN TopMovies tm ON ci.movie_id = tm.movie_id
    WHERE a.name IS NOT NULL
    GROUP BY a.name
)

SELECT 
    tm.title AS movie_title,
    tm.production_year,
    COALESCE(SUM(aw.awards_count), 0) AS total_awards,
    COUNT(DISTINCT ci.person_id) AS total_actors
FROM TopMovies tm
LEFT JOIN cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN ActorsWithAwards aw ON aw.actor_name = aka_name.name
GROUP BY tm.movie_id, tm.title, tm.production_year
ORDER BY total_awards DESC, total_actors DESC;

### Explanation of the SQL Query:

1. **CTEs (Common Table Expressions):**
   - `MovieHierarchy`: This recursive CTE generates a hierarchy of movies starting from those released in the year 2000. It includes all linked movies, creating a structure that allows for hierarchical analysis of movies that are sequels or related.
   - `TopMovies`: This CTE aggregates the top 10 movies based on the number of unique actors in the cast.
   - `ActorsWithAwards`: This CTE counts the awards received by actors associated with the top movies, allowing for insight into the quality of casts.

2. **Main SELECT Statement:**
   - The final query selects the title, production year, total awards count (using `COALESCE` to handle NULLs) and the total number of actors for each of the top movies identified in `TopMovies`.
   - It performs a `LEFT JOIN` between `TopMovies` and the `cast_info` table, allowing for movies with no cast to still appear in the results.

3. **Aggregate Functions:**
   - Uses `COUNT(DISTINCT ...)` to ensure unique counts of actors and awards.
   - Uses `SUM` to aggregate the number of awards across the results.

4. **Ordering:**
   - Results are ordered first by the number of awards received and second by the total number of actors, providing a clear view of top-performing movies.

5. **NULL Logic:**
   - `COALESCE` ensures that null values from the `SUM` function do not impact the overall output when there are no awards.

This complex query not only benchmarks the performance of the SQL structure but also provides rich insights into the relationships and achievements of movies and actors over a specified timeline.
