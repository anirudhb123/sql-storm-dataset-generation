WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mv.title,
    COUNT(DISTINCT c.person_id) AS actor_count,
    SUM(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END) AS total_info_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    AVG(mv.production_year) OVER (PARTITION BY mh.level) AS avg_year,
    MAX(CASE WHEN ao.role = 'Director' THEN ao.person_id ELSE NULL END) AS director_id,
    STRING_AGG(DISTINCT ao.name) FILTER (WHERE ao.role != 'Director') AS other_roles,
    CASE 
        WHEN mv.production_year IS NULL THEN 'Unknown'
        ELSE mv.production_year::TEXT
    END AS production_year_display
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    company_name cn ON cn.id = (SELECT company_id 
                                 FROM movie_companies mc 
                                 WHERE mc.movie_id = mh.movie_id 
                                 LIMIT 1) 
LEFT JOIN 
    person_info pi ON pi.person_id = c.person_id
LEFT JOIN 
    role_type ao ON ao.id = c.role_id
WHERE 
    mh.level <= 2 
GROUP BY 
    mv.title,
    mv.production_year
ORDER BY 
    avg_year DESC NULLS LAST;

This SQL query performs several sophisticated operations:

1. **Recursive CTE**: Builds a hierarchy of movies starting from the year 2000, including linked movies.
2. **Aggregations**: Counts distinct actors, sums total info, and gathers company names.
3. **Window Sum/Avg Function**: Calculates the average production year, partitioned by the hierarchy level.
4. **Complex Filtering**: Uses CASE and string aggregation to differentiate between directors and other roles.
5. **NULL Logic**: Handles potential NULL values in the production year elegantly.
6. **Joins and Outer Joins**: Combines multiple tables and manages the left outer joins for company details. 

This query setup is ideal for performance benchmarking due to its complexity and varied SQL constructs.
