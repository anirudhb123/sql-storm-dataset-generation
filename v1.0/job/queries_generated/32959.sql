WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.movie_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COALESCE(ci.nr_order, 0) AS cast_order,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY m.production_year DESC) AS rank_by_year
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
LEFT JOIN movie_hierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
WHERE m.level = 0 
AND (m.production_year IS NOT NULL AND m.production_year BETWEEN 2000 AND 2023)
GROUP BY a.name, m.title, m.production_year, ci.nr_order
HAVING COUNT(DISTINCT kw.keyword) > 2 OR COALESCE(SUM(CASE WHEN kw.keyword IS NULL THEN 1 ELSE 0 END), 0) > 1
ORDER BY a.name, m.production_year DESC;

### Explanation:
1. **CTE (Common Table Expression)**: A recursive CTE named `movie_hierarchy` is created to retrieve the movies starting from the year 2000 and their linked counterparts through `movie_link`. The level hierarchy reflects the depth of linked relationships.

2. **Main Query**: The main query selects actor names and their associated movies from the `aka_name` and `cast_info` tables, filtering on the hierarchical movies from the CTE.

3. **Left Joins**: Used on `movie_hierarchy` and `movie_keyword` to include details about movies even when some might not have corresponding keywords.

4. **Aggregations**: The query counts distinct keywords associated with each movie and concatenates them into a string.

5. **Row Number Window Function**: This assigns a rank to each actor's movies based on the release year, partitioned by actor names.

6. **Filtering with HAVING**: The results are filtered to include only actors and movies with more than 2 distinct keywords or where there’s at least one NULL keyword in the list.

7. **Ordering**: Finally, results are ordered by actor name and production year to provide a clear structure in the output.
