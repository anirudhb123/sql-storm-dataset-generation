WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        0 AS level
    FROM title m
    WHERE m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mh.level + 1
    FROM movie_link ml
    JOIN title mt ON ml.linked_movie_id = mt.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM movie_hierarchy mh
    LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM ranked_movies rm
    WHERE rm.rank <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(name.name, ak.name) AS actor_name,
    fm.actor_count
FROM filtered_movies fm
LEFT JOIN cast_info ci ON ci.movie_id = fm.movie_id
LEFT JOIN aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN name ON name.imdb_id = ak.person_id
WHERE fm.actor_count IS NOT NULL
AND fm.production_year IS NOT NULL
ORDER BY fm.production_year DESC, fm.actor_count DESC;

### Explanation:
1. **Recursive CTE (movie_hierarchy)**:
   - This part creates a hierarchy of movies starting from those produced in or after 2000. It recursively links to other movies they are associated with via `movie_link`.

2. **Calculating Actor Count**:
   - The `ranked_movies` CTE computes the number of unique actors (`actor_count`) in each movie and ranks them based on the count for each production year.

3. **Filtering for Top Movies**:
   - The `filtered_movies` CTE narrows the result to the top 5 movies for each production year.

4. **Final Selection and Join**: 
   - The outer query fetches movie titles, production years, actor names (from the `aka_name` and `name` tables), and the actor count. It includes checks for NULL values to ensure only complete records are returned.

5. **Ordering Results**:
   - The results are ordered by `production_year` in descending order and by `actor_count` in descending order to highlight the most significant films.

This query combines various SQL constructs such as CTEs, joins (including outer joins), and window functions, making it relatively complex while providing valuable insights into the movie database.
