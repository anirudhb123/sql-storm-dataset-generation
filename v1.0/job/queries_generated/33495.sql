WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
cast_ranks AS (
    SELECT 
        ci.movie_id,
        a.name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mh.movie_id) AS info_count,
    k.keyword_count,
    (CASE 
        WHEN k.keyword_count IS NULL THEN 'No Keywords'
        ELSE 'Has Keywords'
     END) AS keyword_status,
    COUNT(DISTINCT c.name) AS cast_count,
    MAX(cr.role_order) AS max_role_order
FROM 
    movie_hierarchy mh
LEFT JOIN 
    keyword_counts k ON mh.movie_id = k.movie_id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_ranks cr ON mh.movie_id = cr.movie_id
LEFT JOIN 
    aka_title at ON mh.movie_id = at.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, k.keyword_count
HAVING 
    mh.production_year >= 2000 
    AND COUNT(DISTINCT c.name) >= 2
ORDER BY 
    mh.production_year DESC, 
    keyword_status, 
    cast_count DESC;
