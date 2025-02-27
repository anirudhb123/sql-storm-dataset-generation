WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN ci.role_id IS NOT NULL THEN ci.person_id END) AS distinct_roles,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE NULL END) AS avg_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),

keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

company_summary AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.distinct_roles, 0) AS distinct_roles,
    COALESCE(cs.avg_order, 0.0) AS avg_order,
    COALESCE(ks.keywords, 'No Keywords') AS keywords,
    COALESCE(cs.total_cast, 0) * 1.0 / NULLIF(cs.distinct_roles, 0) AS cast_role_ratio,
    COALESCE(cmp.total_companies, 0) AS total_companies,
    mh.level AS movie_level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
LEFT JOIN 
    company_summary cmp ON mh.movie_id = cmp.movie_id
WHERE 
    (mh.production_year > 2000 OR mh.production_year IS NULL) 
    AND (mh.title IS NOT NULL AND mh.title <> '')
ORDER BY 
    mh.level DESC, 
    movie_id
LIMIT 100;

