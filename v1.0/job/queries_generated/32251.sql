WITH RECURSIVE CastHierarchy AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        1 AS hierarchy_level
    FROM cast_info ci
    WHERE ci.role_id IS NOT NULL

    UNION ALL

    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        ch.hierarchy_level + 1
    FROM cast_info ci
    JOIN CastHierarchy ch ON ci.movie_id = ch.movie_id
    WHERE ci.person_id = ch.person_id
)

SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(ci.person_id) AS total_cast,
    MAX(ci.nr_order) AS max_order,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ah.hierarchy_level DESC) AS cast_level

FROM title t
INNER JOIN aka_title at ON t.id = at.movie_id
LEFT JOIN cast_info ci ON t.id = ci.movie_id
LEFT JOIN aka_name a ON ci.person_id = a.person_id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword kt ON mk.keyword_id = kt.id
LEFT JOIN CastHierarchy ah ON ci.movie_id = ah.movie_id AND ci.person_id = ah.person_id

WHERE
    t.production_year >= 2000
    AND at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    AND a.name IS NOT NULL

GROUP BY 
    t.id, a.name
HAVING 
    COUNT(ci.person_id) > 3
ORDER BY 
    t.title, max_order DESC;

This query constitutes an elaborate SQL statement that utilizes:
- A recursive CTE called `CastHierarchy` to create a hierarchy based on `cast_info`.
- INNER JOINs, LEFT JOINs, GROUP BY with HAVING clause to filter results.
- Window function `ROW_NUMBER()` to rank cast levels per movie.
- String aggregation with `STRING_AGG` to concatenate unique keywords for each movie.
- Complex conditions in the WHERE clause for filtering relevant titles and roles.
