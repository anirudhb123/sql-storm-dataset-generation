WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        ma.title,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title ma ON ma.id = ml.linked_movie_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COUNT(DISTINCT m.id) AS linked_movie_count,
    ARRAY_AGG(DISTINCT rh.movie_title) AS related_movies,
    AVG(CASE WHEN wi.role IS NULL THEN 0 ELSE 1 END) AS role_ratio
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON at.id = ci.movie_id
LEFT JOIN 
    MovieHierarchy m ON m.movie_id = at.id
LEFT JOIN 
    role_type wi ON wi.id = ci.role_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND at.production_year IS NOT NULL
    AND (wi.role IS NULL OR wi.role != 'Unknown')
GROUP BY 
    ak.name, at.title
HAVING 
    COUNT(DISTINCT m.movie_id) > 3
ORDER BY 
    actor_name,
    movie_title DESC;

### Explanation:

1. **CTE**: A recursive Common Table Expression (CTE) called `MovieHierarchy` is created to build a hierarchy of movies that are linked together starting from movies produced from the year 2000. 

2. **Joins**: The query includes multiple joins:
   - `aka_name` to get actors' names.
   - `cast_info` to connect actors to movies.
   - `aka_title` to retrieve movie titles.
   - A left join with the `MovieHierarchy` CTE to gather information about linked movies.
   - A left join with `role_type` to gather the roles played by actors.

3. **Aggregation**:
   - `COUNT(DISTINCT m.id) AS linked_movie_count` counts the distinct number of linked movies.
   - `ARRAY_AGG(DISTINCT rh.movie_title)` aggregates the titles of movies related to the main movie in the hierarchy.
   - `AVG(CASE WHEN wi.role IS NULL THEN 0 ELSE 1 END) AS role_ratio` calculates the ratio of defined roles where NULL entries are counted as zero.

4. **Filters and Having Clause**: 
   - Various predicates ensure valid data (e.g., names not NULL or empty).
   - The `HAVING` clause filters results to only include actors who have more than 3 distinct linked movies.

5. **Ordering**: The results are ordered by actor's name and movie title in descending order.

This query is optimal for performance benchmarking, incorporating various SQL features and constructs.
