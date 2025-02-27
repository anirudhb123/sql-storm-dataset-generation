WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS hierarchy_level,
        ARRAY[mt.id] AS path
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        mh.hierarchy_level + 1,
        mh.path || ml.linked_movie_id
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE ml.linked_movie_id IS NOT NULL
)

SELECT 
    ak.name AS actor_name,
    ak.id AS actor_id,
    mh.movie_title,
    mh.hierarchy_level,
    COUNT(DISTINCT mc.company_id) AS companies_involved,
    STRING_AGG(DISTINCT kc.keyword, ', ') AS associated_keywords,
    AVG(mi.year) AS avg_year_info
FROM actor ak
JOIN cast_info ci ON ak.id = ci.person_id
JOIN movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword kc ON mk.keyword_id = kc.id
LEFT JOIN (
    SELECT 
        movie_id,
        EXTRACT(YEAR FROM MIN(production_year)) AS year
    FROM aka_title
    GROUP BY movie_id
) mi ON mh.movie_id = mi.movie_id
WHERE ak.gender IS NOT NULL
AND mh.hierarchy_level <= 3
GROUP BY ak.id, ak.name, mh.movie_title, mh.hierarchy_level
HAVING COUNT(DISTINCT mc.company_id) > 0
AND STRING_AGG(DISTINCT kc.keyword, ', ') IS NOT NULL
ORDER BY mh.hierarchy_level DESC, actor_name;

### Explanation:
1. **Common Table Expression (CTE)**: `movie_hierarchy` recursively builds a hierarchy of movies linked to each other through `movie_link`, capturing the movie titles, hierarchy levels, and paths.

2. **Main SELECT Statement**: Retrieves data about actors from `aka_name` (`ak`), their roles in movies, and associated production companies and keywords.

3. **Aggregations**: Uses aggregate functions such as `COUNT`, `AVG`, and `STRING_AGG` to summarize data regarding the companies involved and keywords associated with each movie.

4. **Correlated Subqueries**: Incorporates a subquery to find the minimum production year for movies, demonstrating a level of complexity by integrating multidimensional data.

5. **Null Logic**: Ensures that certain fields are not null in the WHERE clause to avoid skewed results.

6. **Filtering and Grouping**: Groups results by actor and movie while filtering hierarchically to limit results to specific levels in the movie chain (not greater than 3).

7. **Ordering**: Orders results by hierarchy to view higher-level movies first and alphabetically by actor name.

This query leverages many SQL features, making it elaborate and potentially useful for performance benchmarking while also serving as an illustration of advanced SQL capabilities.
