WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 5  -- Limit to 5 levels deep in the hierarchy
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    SUM(CASE WHEN a.name IS NOT NULL THEN 1 ELSE 0 END) AS named_actors,
    COALESCE(MAX(mh.depth), 0) AS max_depth,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
WHERE 
    a.name IS NOT NULL 
    AND (a.imdb_index IS NOT NULL OR a.surname_pcode IS NOT NULL)  -- Example of compound predicates
GROUP BY 
    a.id
HAVING 
    COUNT(DISTINCT c.movie_id) > 3  -- Filtration on having condition
ORDER BY 
    movie_count DESC
LIMIT 50;

### Explanation of Constructs:

- **CTE with Recursion**: `movie_hierarchy` CTE builds a hierarchy of movies with respect to their links and limits the depth to 5. This is to analyze movie relationships at different generational levels.
- **LEFT JOINs**: Multiple tables are joined, such as `aka_name`, `cast_info`, `movie_keyword`, and `keyword`, allowing for a comprehensive view of actors and their movies, along with associated keywords.
- **Aggregations**: Used `COUNT`, `SUM`, and `STRING_AGG` to accumulate results based on various criteria such as distinct movies per actor and associated keywords.
- **Conditional Logic**: `CASE WHEN` and `COALESCE` are incorporated to handle NULL values and provide default behavior where necessary.
- **Window Function**: Utilized `ROW_NUMBER()` to rank actors based on the number of distinct movies they have appeared in.
- **HAVING Clause**: Filters results further to only include actors with more than three movies.
- **Bizarre Semantics**: The query includes a potential compound predicate where both the `imdb_index` and `surname_pcode` could grant inclusion, which could arouse special interest in edge cases with NULL logic.
