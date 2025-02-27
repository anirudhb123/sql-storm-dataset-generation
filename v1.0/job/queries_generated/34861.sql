WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, 0 AS level
    FROM aka_title m
    WHERE m.production_year = 2022  -- Start from movies produced in 2022

    UNION ALL

    SELECT m.id, m.title, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.level < 3  -- Limit to depth of 3 levels
),

top_roles AS (
    SELECT c.movie_id, c.role_id, COUNT(c.id) as role_count
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id, c.role_id
    HAVING COUNT(c.id) > 2  -- More than 2 occurrences of the role
),

popular_movies AS (
    SELECT mh.movie_id, mh.title, COUNT(DISTINCT c.person_id) AS actor_count
    FROM movie_hierarchy mh
    LEFT JOIN cast_info c ON mh.movie_id = c.movie_id
    GROUP BY mh.movie_id, mh.title
    HAVING COUNT(DISTINCT c.person_id) > 5  -- Must have more than 5 distinct actors
),

movies_with_keywords AS (
    SELECT m.id AS movie_id, ARRAY_AGG(k.keyword) AS keywords
    FROM aka_title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id
),

final_results AS (
    SELECT pm.movie_id, pm.title, pm.actor_count, mk.keywords
    FROM popular_movies pm
    LEFT JOIN movies_with_keywords mk ON pm.movie_id = mk.movie_id
)

SELECT fr.title,
       fr.actor_count,
       COALESCE(STRING_AGG(DISTINCT fr.keywords::text, ', '), 'No keywords') AS keywords,
       CASE WHEN fr.actor_count > 10 THEN 'Highly Popular' ELSE 'Moderately Popular' END AS popularity_level
FROM final_results fr
GROUP BY fr.movie_id, fr.title, fr.actor_count
ORDER BY fr.actor_count DESC, fr.title
LIMIT 10;  -- Get only the top 10 most popular movies

This SQL query does the following:

1. **CTE (Common Table Expressions)**:
   - `movie_hierarchy`: Retrieves movies produced in 2022 and recursively linked movies up to a depth of 3.
   - `top_roles`: Counts occurrences of roles in the cast and filters for roles occurring more than 2 times.
   - `popular_movies`: Counts distinct actors in the movies from the `movie_hierarchy` and filters for movies with more than 5 unique actors.
   - `movies_with_keywords`: Aggregates keywords associated with each movie.

2. **Final Selection**:
   - Combines the results of popular movies with their keywords, categorizes their popularity level, and formats output with string aggregation.

3. **NULL Logic**: Uses `COALESCE` to handle scenarios where no keywords exist. 

4. **Aggregate Functions**: Utilizes `COUNT`, `STRING_AGG`, and `ARRAY_AGG` for statistical summaries.

5. **Sorting and Limiting**: Orders by actor count and limits the results to the top 10 most popular movies.
