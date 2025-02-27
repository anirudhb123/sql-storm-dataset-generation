WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    WHERE 
        mh.level < 5
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    ci.note AS role_note,
    COUNT(DISTINCT mh.movie_id) AS linked_movie_count,
    STRING_AGG(DISTINCT ci.note, '; ') AS role_notes, 
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS role_rank,
    CASE 
        WHEN ci.nr_order IS NULL THEN 'N/A'
        ELSE CAST(ci.nr_order AS TEXT)
    END AS role_order,
    COALESCE(SUM(CASE WHEN mt.production_year < 2000 THEN 1 ELSE 0 END), 0) AS pre_2000_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
WHERE 
    ci.note IS NOT NULL AND ci.note <> ''
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, at.title, at.production_year, ci.note, ci.nr_order
HAVING 
    COUNT(DISTINCT mh.movie_id) > 3
ORDER BY 
    role_rank, ak.name;

-- Observations:
-- 1. This query collects a list of actors with the titles they were affiliated with.
-- 2. It includes a hierarchical view of linked movies up to 5 levels deep.
-- 3. Utilizes window functions to rank roles and aggregates role notes.
-- 4. NULL values are handled specifically and may change results for roles without an order.
-- 5. FILTERS: It removes any roles that do not have a note or actor names which are NULL.
-- 6. The use of STRING_AGG provides a comprehensive overview of an actor's roles in various movies.
