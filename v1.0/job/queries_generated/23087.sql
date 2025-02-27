WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year IS NOT NULL
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_roles,
    COUNT(DISTINCT c.person_id) AS cast_count,
    ARRAY_AGG(DISTINCT cn.name) AS company_names,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_within_year
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 0 AND
    MIN(m.production_year) < 2000
ORDER BY 
    m.production_year DESC,
    total_roles DESC
LIMIT 100 OFFSET 0;
