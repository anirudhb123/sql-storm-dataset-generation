WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'

    UNION ALL

    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(a.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    SUM(CASE WHEN mt.info IS NOT NULL THEN 1 ELSE 0 END) AS has_additional_info,
    ROW_NUMBER() OVER (PARTITION BY m.title ORDER BY m.production_year DESC) AS row_num
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    movie_info_idx mt ON m.movie_id = mt.movie_id AND mi.info_type_id = mt.info_type_id
WHERE 
    (m.production_year > 2000 OR m.production_year IS NULL)
    AND (c.role_id IS NOT NULL OR c.note IS NULL)
GROUP BY 
    m.title, m.production_year, a.name
HAVING 
    COUNT(DISTINCT a.person_id) > 1
ORDER BY 
    m.production_year DESC, movie_title;

This SQL query creates a recursive common table expression (CTE) to gather movie data, enhanced by various joins, aggregates, window functions, and filtering logic, showcasing the breadth of SQL capabilities on the given schema.
