WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.id AS movie_id,
    m.title,
    COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    MAX(mh.level) AS hierarchy_level,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(CASE WHEN mpi.info IS NOT NULL THEN 1 ELSE NULL END) AS average_personal_info,
    NTILE(3) OVER (PARTITION BY EXTRACT(YEAR FROM m.production_year) ORDER BY m.production_year) AS production_year_quartile
FROM 
    aka_title m
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    movie_info mpi ON m.id = mpi.movie_id
LEFT JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    m.production_year IS NOT NULL 
    AND m.title NOT LIKE '%Untitled%'
GROUP BY 
    m.id, m.title
ORDER BY 
    cast_count DESC, 
    keyword_count DESC
LIMIT 50;
