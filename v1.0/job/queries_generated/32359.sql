WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        1 AS level,
        COALESCE(SUM(CASE WHEN mc.company_type_id = ct.id THEN 1 ELSE 0 END), 0) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.level + 1,
        mh.company_count
    FROM 
        movie_hierarchy mh
    INNER JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 3  -- Limit to 3 levels of depth
)

SELECT 
    mh.movie_id, 
    mh.title,
    mh.level,
    mh.company_count,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = mh.movie_id) AS cast_size,
    (SELECT 
        STRING_AGG(DISTINCT k.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = mh.movie_id) AS keywords
FROM 
    movie_hierarchy mh
WHERE 
    mh.company_count > 0
ORDER BY 
    mh.level, mh.company_count DESC, cast_size DESC;
