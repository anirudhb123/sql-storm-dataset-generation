WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level,
        CAST(mh.path || ' -> ' || m.title AS VARCHAR(255)) AS path
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title m ON mh.movie_id = m.episode_of_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(ci.id) AS roles_count,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
    STRING_AGG(DISTINCT cct.kind, ', ') AS cast_types,
    CASE 
        WHEN COUNT(ci.id) > 5 THEN 'Experienced'
        ELSE 'Novice'
    END AS experience_level,
    mh.path AS movie_hierarchy
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
LEFT JOIN 
    comp_cast_type cct ON ci.person_role_id = cct.id
LEFT JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, mh.path
HAVING 
    COUNT(ci.id) > 1
ORDER BY 
    avg_order DESC,
    roles_count DESC;

### Explanation:

1. **Common Table Expression (CTE)**: The recursive CTE `MovieHierarchy` builds a hierarchy of movies for those that are episodes, allowing you to track sub-series relationships.

2. **Joins**: The query features both inner and outer joins to accumulate data about cast members from various tables.

3. **Aggregations**: The query utilizes aggregate functions like `COUNT`, `AVG`, and `STRING_AGG` to compile statistics on actors and their roles.

4. **Conditional Logic**: The `CASE` statement classifies actors based on their roles into 'Experienced' or 'Novice'.

5. **Complicated Predicate**: It filters movies released after 2000 and ensures that actor names are not NULL.

6. **HAVING Clause**: Ensures that only actors with more than one role are included in the results.

7. **Order By**: Results are ordered by average role order and count of roles, providing an insightful view of the actors' careers in the context of their popularity in recent years.

This query's complexity reflects realistic data handling scenarios in large databases while benchmarking the performance of joins, aggregations, and CTEs.
