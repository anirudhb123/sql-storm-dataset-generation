WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Base case: Select only movies

    UNION ALL

    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Recursive case: Join linked movies 
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    SUM(CASE WHEN m.production_year >= 2000 THEN 1 ELSE 0 END) AS movies_since_2000,
    STRING_AGG(DISTINCT ct.kind, ', ') AS company_types,
    AVG(mh.level) AS avg_link_level
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
WHERE 
    a.name IS NOT NULL
    AND a.name <> ''
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    movie_count DESC
LIMIT 10;

This query aims to achieve performance benchmarking by leveraging multiple SQL constructs, including:
- A recursive Common Table Expression (CTE) to traverse linked movies.
- Aggregations such as `COUNT`, `SUM`, and `AVG`.
- String aggregation with `STRING_AGG` to concatenate company types.
- Various join types including left joins to include all records from `cast_info` even if there are no matching records in joined tables.
- Excluding NULL or empty names in the WHERE clause.
- A HAVING clause to filter actors who have appeared in more than 5 movies.
- The final result is ordered by the number of movies, limited to the top 10 actors.

This query effectively showcases performance and complexity in SQL querying.
