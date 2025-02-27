WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        1 AS level,
        m.production_year
    FROM title m
    WHERE m.kind_id = 1  -- Assuming 'kind_id = 1' means it's a movie

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        mh.level + 1,
        m.production_year
    FROM title m
    INNER JOIN movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT c.kind ORDER BY c.kind) AS company_types,
    DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rank
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword kc ON mk.keyword_id = kc.id
LEFT JOIN movie_companies mc ON t.id = mc.movie_id
LEFT JOIN company_type c ON mc.company_type_id = c.id
WHERE t.production_year IS NOT NULL
  AND a.name IS NOT NULL
  AND t.id NOT IN (
    SELECT movie_id 
    FROM complete_cast 
    WHERE status_id NOT IN (1, 2)  -- Excluding specific statuses
)
GROUP BY a.name, t.title, t.production_year
HAVING COUNT(DISTINCT kc.keyword) > 5  -- Only movies with more than 5 different keywords
ORDER BY t.production_year DESC, rank;

### Explanation:
1. **Common Table Expression (CTE)**: A recursive CTE `movie_hierarchy` is created to navigate through movie links. This assumes there's a hierarchical relationship (parent and child movies).
  
2. **Main Query**:
   - **Joins**: Combines multiple tables to gather actor names, their movies, company types associated with those movies, and the count of unique keywords.
   - **LEFT JOINs**: Used for `movie_keyword` and `movie_companies` to include companies and keywords even if they don't exist for all movies.
   - **Filtering**: Keeps only relevant records by checking non-null values and excluding movies based on specific statuses from the `complete_cast` table.
   - **Aggregation**: Counts distinct keywords and gathers unique company types into an array.
   - **Window Function**: Uses `DENSE_RANK()` to rank movies within each production year based on the number of distinct keywords, which provides insight into movies with a rich description.
   - **HAVING Clause**: Ensures that only movies with more than 5 keywords are kept in the results.
  
3. **Ordering**: Finally sorts results by production year and rank to give a clear output.
