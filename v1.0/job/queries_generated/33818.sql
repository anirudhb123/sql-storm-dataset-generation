WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           0 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.level < 3
),

cast_details AS (
    SELECT ci.movie_id, 
           COUNT(*) AS cast_count,
           STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM cast_info ci
    INNER JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
),

keyword_counts AS (
    SELECT mk.movie_id, 
           COUNT(*) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),

ranked_movies AS (
    SELECT mh.movie_id, 
           mh.title, 
           mh.production_year, 
           cd.cast_count, 
           kc.keyword_count,
           ROW_NUMBER() OVER (ORDER BY mh.production_year DESC, cd.cast_count DESC) AS rank
    FROM movie_hierarchy mh
    LEFT JOIN cast_details cd ON mh.movie_id = cd.movie_id
    LEFT JOIN keyword_counts kc ON mh.movie_id = kc.movie_id
)

SELECT rm.title, 
       rm.production_year, 
       COALESCE(rm.cast_count, 0) AS total_cast, 
       COALESCE(rm.keyword_count, 0) AS total_keywords, 
       rm.rank,
       (SELECT COUNT(DISTINCT c.id) 
        FROM complete_cast cc
        JOIN aka_title c ON cc.movie_id = c.id
        WHERE c.production_year = rm.production_year) AS movies_by_year
FROM ranked_movies rm
WHERE rm.rank <= 10
ORDER BY rm.rank;

### Explanation:
1. **CTE - movie_hierarchy**: A recursive CTE that pulls movies from the `aka_title` table produced year 2000 and later, and constructs a hierarchy (up to 3 levels) of linked movies.
  
2. **CTE - cast_details**: Aggregates cast information for each movie, counting the number of distinct cast members and listing their names.

3. **CTE - keyword_counts**: Counts the keywords associated with each movie.

4. **CTE - ranked_movies**: Combines the previous CTEs to produce a ranked list of movies based on their production year and cast count using a `ROW_NUMBER` window function.

5. **Final SELECT**: Gathers the final results, choosing only the top 10 ranked movies, and incorporates a correlated subquery to count how many distinct movies were released in the same year as each selected movie, even when that movie has no cast or keywords.

This query demonstrates various SQL concepts such as recursive CTEs, aggregations, window functions, outer joins, and correlated subqueries.
