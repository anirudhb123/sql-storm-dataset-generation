WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.movie_id,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    STRING_AGG(DISTINCT CONCAT(n.name, ' (', COALESCE(r.role, 'Unknown'), ')'), ', ') AS actors,
    MAX(COALESCE(ci.note, 'No Note')) AS note,
    CASE
        WHEN mh.level = 0 THEN 'Main Movie'
        WHEN mh.level > 0 THEN 'Related Movie'
        ELSE 'Unknown Level'
    END AS movie_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    cast_info c ON c.movie_id = mh.movie_id
LEFT JOIN 
    role_type r ON r.id = c.role_id
LEFT JOIN 
    aka_name n ON n.person_id = c.person_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
WHERE 
    mi.info IS NOT NULL OR mi.note IS NULL
GROUP BY 
    mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT c.person_id) > 1
ORDER BY 
    mh.production_year DESC, actor_count DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM aka_title) / 2;

This SQL query does the following:

1. **Recursive CTE (`MovieHierarchy`)**: Generates a hierarchy of movies starting from movies produced in 2000 and later, allowing it to include related movies connected through `movie_link`.

2. **Outer Joins**: Utilizes outer joins to gather information from various related tables such as `movie_companies`, `company_name`, `cast_info`, and `role_type`.

3. **Aggregations**: Counts distinct actors involved and concatenates their details using `STRING_AGG`, handling `NULL` values appropriately through `COALESCE`.

4. **Complex Predicates**: Places complex conditions in the `WHERE` clause to ensure that relevant movie information is captured.

5. **Grouping and Having Clauses**: Groups results by movie title, production year, and level in the hierarchy, ensuring that only movies with more than one actor are selected.

6. **Ordering and Limiting**: Orders results by production year and actor count, with an interesting usage of pagination by limiting to half the total number of entries from `aka_title`.

This query is designed to benchmark performance by including various constructs and complexities typical in real-world scenarios, enabling analysis across a detailed schema with interconnected relationships.
