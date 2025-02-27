WITH RECURSIVE actor_hierarchy AS (
    SELECT a.id AS actor_id,
           a.name AS actor_name,
           ca.movie_id,
           1 AS depth
    FROM aka_name a
    JOIN cast_info ca ON a.person_id = ca.person_id
    WHERE a.name IS NOT NULL
    
    UNION ALL
    
    SELECT a.id,
           a.name,
           ca.movie_id,
           ah.depth + 1
    FROM aka_name a
    JOIN cast_info ca ON a.person_id = ca.person_id
    JOIN actor_hierarchy ah ON ca.movie_id = ah.movie_id
    WHERE a.name IS NOT NULL AND ah.actor_id <> a.id
),
movie_details AS (
    SELECT mt.title,
           mt.production_year,
           COUNT(DISTINCT ah.actor_id) AS actor_count,
           AVG(ah.depth) AS avg_depth
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN actor_hierarchy ah ON ci.person_id = ah.actor_id
    WHERE mt.kind_id IS NOT NULL
    GROUP BY mt.title, mt.production_year
),
movie_keywords AS (
    SELECT mk.movie_id,
           STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT md.title,
       md.production_year,
       md.actor_count,
       md.avg_depth,
       COALESCE(mk.keywords_list, 'No keywords') AS keywords,
       CASE 
           WHEN md.production_year < 2000 THEN 'Classic'
           WHEN md.production_year BETWEEN 2000 AND 2015 THEN 'Modern'
           ELSE 'Recent'
       END AS era
FROM movie_details md
LEFT JOIN movie_keywords mk ON md.movie_id = mk.movie_id
WHERE md.actor_count > 5
ORDER BY md.production_year DESC, md.actor_count DESC;

This SQL query performs a performance benchmark by analyzing details about movies and their corresponding actors. Here’s a breakdown of what it does:

1. **CTEs (Common Table Expressions)**:
   - `actor_hierarchy`: This recursive CTE captures actors and their roles in movies, tracking the depth of their participation.
   - `movie_details`: This aggregates titles, their production years, counts of unique actors, and calculates the average depth of the cast from `actor_hierarchy`.
   - `movie_keywords`: This collects keywords associated with each movie.

2. **Main Query**: 
   - It selects movie titles and production years from `movie_details`, adds keyword information using a left join on `movie_keywords`, and classifies the era based on the year the movie was produced.
   - The results are filtered to include only movies with more than 5 actors.

3. **String Aggregation**: It uses `STRING_AGG` to create a comma-separated list of keywords for each movie.

4. **Complex Case Statement**: A `CASE` expression categorizes movies into 'Classic', 'Modern', or 'Recent' based on their production year.

5. **NULL Handling**: `COALESCE` is used to handle cases where a movie may not have associated keywords.

This query demonstrates various advanced SQL techniques and constructs while addressing performance benchmarking concerns by aggregating data efficiently.
