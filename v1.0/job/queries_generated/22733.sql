WITH RECURSIVE cast_hierarchy AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        1 AS level,
        ARRAY[ci.person_id] AS hierarchy
    FROM cast_info ci
    WHERE ci.nr_order = 1  -- Starting point: top-most cast member

    UNION ALL

    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        ch.level + 1,
        ch.hierarchy || ci.person_id  -- Build hierarchy path
    FROM cast_info ci
    JOIN cast_hierarchy ch ON ci.movie_id = ch.movie_id 
        AND ci.person_id <> ALL(ch.hierarchy  -- Avoid cyclical references
        )
)
SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    COUNT(DISTINCT ch.person_id) OVER (PARTITION BY t.id ORDER BY t.production_year) AS number_of_roles,
    string_agg(DISTINCT kc.keyword, ', ') AS keywords,
    COALESCE(MAX(mi.info) FILTER (WHERE it.info = 'Box Office'), 'N/A') AS box_office,
    COALESCE(MIN(CASE WHEN c.kind IS NULL THEN 'Unknown' ELSE c.kind END), 'No Type') AS company_type,
    ARRAY_AGG(DISTINCT ca.name) FILTER (WHERE ca.name IS NOT NULL) AS distinct_characters
FROM aka_title at
JOIN title t ON at.movie_id = t.id
JOIN cast_info ci ON ci.movie_id = t.id
JOIN aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN keyword kc ON mk.keyword_id = kc.id
LEFT JOIN movie_companies mc ON mc.movie_id = t.id
LEFT JOIN company_type c ON mc.company_type_id = c.id
LEFT JOIN movie_info mi ON mi.movie_id = t.id
LEFT JOIN info_type it ON mi.info_type_id = it.id
LEFT JOIN char_name ca ON ca.imdb_index = ak.imdb_index  -- Assuming characters share indices
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ak.name IS NOT NULL
GROUP BY 
    t.id, ak.name
HAVING 
    COUNT(DISTINCT ch.person_id) > 1  -- Movies with more than one role
ORDER BY 
    t.production_year DESC, 
    number_of_roles DESC,
    actor_name ASC
LIMIT 50;

-- The use of recursive CTEs allows for exploring complex hierarchies within the cast,
-- while window functions and filtering enhance the analysis of movie statistics.
