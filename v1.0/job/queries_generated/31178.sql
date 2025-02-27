WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.movie_id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
),
cast_average AS (
    SELECT 
        ci.movie_id,
        AVG(COALESCE(NULLIF(ci.nr_order, 0), NULL)) AS avg_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
company_count AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    k.keyword,
    cc.total_companies,
    ca.avg_order,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY ca.avg_order DESC) AS rank_within_year
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    company_count cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_average ca ON mh.movie_id = ca.movie_id
WHERE 
    mh.depth = 1 AND 
    (cc.total_companies IS NULL OR cc.total_companies < 5) AND 
    (mh.production_year > 2000)
ORDER BY 
    mh.production_year, 
    rank_within_year;
