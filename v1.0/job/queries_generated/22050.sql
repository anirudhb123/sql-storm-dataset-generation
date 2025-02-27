WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        CAST(mt.title AS VARCHAR) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        CAST(CONCAT(mh.path, ' -> ', at.title) AS VARCHAR)
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies_linked,
    STRING_AGG(DISTINCT mh.path, '; ') AS linked_movie_paths,
    AVG(CASE WHEN at.production_year IS NOT NULL THEN at.production_year ELSE NULL END) AS avg_production_year
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title at ON mh.movie_id = at.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre') 
WHERE 
    ak.name IS NOT NULL
    AND ak.name NOT LIKE '%[[]%[%]%]' -- Exclude names with brackets
    AND ak.name != '' 
GROUP BY 
    ak.name 
HAVING 
    SUM(CASE WHEN at.kind_id IS NOT NULL THEN 1 ELSE 0 END) > 0 
ORDER BY 
    total_movies_linked DESC
FETCH FIRST 10 ROWS ONLY;

### Explanation of SQL Constructs:
1. **CTE Recursive**: `movie_hierarchy` starts with original movies and recursively joins to find linked movies, maintaining a path.
2. **JOINs**: Multiple joins connect actors to their films and breadth of linked movies, using left join for optional genre info.
3. **CASE Statements**: Used for average production year calculations while handling NULL values.
4. **STRING_AGG**: Aggregates multiple movie paths into a single string for better readability.
5. **HAVING clause**: Filters out any actor not participating in films of any kind using a conditional sum within the group.
6. **Obscure edge-case handling**: Filters out names with brackets, empty names in a bizarre way.
7. **Ordering and Row Limiting**: Orders by total linked movies and limits the result to the top 10 actors.

