
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL AS parent_id
    FROM title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(cn.name, 'Unknown Company') AS company_name,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    AVG(COALESCE(ci.nr_order, 0)) AS avg_cast_order,
    STRING_AGG(DISTINCT a.name, ', ') AS aka_names,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast_size,
    MAX(mh.level) AS hierarchy_level
FROM 
    movie_hierarchy mh
JOIN 
    title m ON mh.movie_id = m.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
WHERE 
    m.production_year >= 2000
GROUP BY 
    m.id, m.title, m.production_year, cn.name
ORDER BY 
    avg_cast_order DESC,
    cast_count DESC;
