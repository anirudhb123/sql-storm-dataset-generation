WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level,
        CAST(t.title AS VARCHAR(255)) AS path
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || lt.title AS VARCHAR(255))
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
)

SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COUNT(c.id) AS total_cast_members,
    STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') AS cast_details,
    COALESCE(MAX(mi.info), 'No Info') AS additional_info,
    SUM(CASE WHEN c.nr_order < 10 THEN 1 ELSE 0 END) AS early_roles_count,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    mh.path AS movie_path
FROM 
    aka_title m
LEFT JOIN 
    cast_info c ON m.id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    movie_keyword k ON m.id = k.movie_id
LEFT JOIN 
    MovieHierarchy mh ON m.id = mh.movie_id
WHERE 
    m.production_year >= 2000
GROUP BY 
    m.id, m.title, m.production_year, mh.path
ORDER BY 
    m.production_year DESC, total_cast_members DESC;

This SQL query involves a recursive Common Table Expression (CTE) to build a hierarchy of movies based on their links, it aggregates cast member details, counts separate categories, and includes conditionals for handling NULL values and production year filters. The output includes a structured path of linked movies and detailed insights into the cast and related keywords.
