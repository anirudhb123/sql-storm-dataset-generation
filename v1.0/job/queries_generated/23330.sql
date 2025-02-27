WITH RECURSIVE cast_hierarchy AS (
    SELECT 
        c.movie_id,
        a.person_id,
        a.name,
        CASE 
            WHEN r.role IS NOT NULL THEN r.role 
            ELSE 'Unknown Role' 
        END AS role_name,
        1 AS hierarchy_level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL

    UNION ALL

    SELECT 
        ch.movie_id,
        a.person_id,
        a.name,
        'Cameo' AS role_name,
        ch.hierarchy_level + 1
    FROM 
        cast_hierarchy ch
    JOIN 
        cast_info c ON ch.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        ch.hierarchy_level < 5 -- Limit depth of recursion
)
SELECT 
    m.id AS movie_id,
    m.title,
    COUNT(DISTINCT ch.person_id) AS total_cast,
    ARRAY_AGG(DISTINCT ch.role_name) AS roles,
    AVG(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE 0 END) AS avg_production_year,
    STRING_AGG(DISTINCT a."name", ', ') FILTER (WHERE a."name" IS NOT NULL) AS cast_names,
    MAX(ch.hierarchy_level) AS max_cast_level
FROM 
    title m
LEFT JOIN 
    cast_hierarchy ch ON m.id = ch.movie_id
LEFT JOIN 
    aka_name a ON ch.person_id = a.person_id
GROUP BY 
    m.id, m.title
HAVING 
    COUNT(DISTINCT ch.person_id) > 0 
    AND MAX(ch.hierarchy_level) BETWEEN 1 AND 3
ORDER BY 
    total_cast DESC, avg_production_year ASC 
LIMIT 10;

### Explanation:
- **CTE (`cast_hierarchy`)**: A recursive common table expression is created to build a hierarchy of cast members for each movie. It starts with the primary cast and allows for depth up to 5, characterizing an additional layer as 'Cameo'.
- **Outer Joins**: The main query uses `LEFT JOIN` to include movies with no cast listed (though we only filter out those with zero cast members in the `HAVING` clause).
- **Aggregations**: `COUNT(DISTINCT ...)` for counting unique cast member IDs, `ARRAY_AGG` to collect distinct roles played, `AVG` for the average production year, and `STRING_AGG` for combining cast names.
- **Complicated Predicates**: There’s a mixed usage of `CASE` inside average to handle possible NULLs in production year and using `FILTER` in the string aggregation to ignore NULL names.
- **HAVING Clause**: Ensures that only movies with at least one cast member and a caste hierarchy level between 1 and 3 are included.
- **Ordering**: The results are sorted first by the total number of unique cast members in descending order, followed by the average production year in ascending order, returning up to 10 results.
