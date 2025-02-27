WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(m.production_year::text, 'Unknown') AS production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(m.production_year::text, 'Unknown') AS production_year,
        mh.level + 1
    FROM 
        aka_title AS m
    INNER JOIN 
        MovieHierarchy AS mh ON m.episode_of_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    cc.kind AS company_type,
    AVG(COALESCE(mi.info::float, 0)) AS avg_info_value,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    COUNT(DISTINCT mc.company_id) AS involved_companies,
    SUM(CASE WHEN ci.nr_order IS NULL THEN 1 ELSE 0 END) AS null_order_count
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    movie_companies AS mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type AS cc ON mc.company_type_id = cc.id
LEFT JOIN 
    movie_info AS mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Revenue')
LEFT JOIN 
    cast_info AS ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_title AS ak ON mh.movie_id = ak.movie_id
WHERE 
    mh.production_year = '2023' OR mh.production_year = 'Unknown'
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, cc.kind
ORDER BY 
    mh.movie_title ASC, avg_info_value DESC
LIMIT 100;
