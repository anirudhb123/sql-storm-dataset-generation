WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mt.production_year >= 2000
),

cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS credited_cast
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
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cs.total_cast,
    cs.credited_cast,
    ks.keywords,
    co.companies,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.depth, mh.title) AS movie_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
LEFT JOIN 
    company_summary co ON mh.movie_id = co.movie_id
WHERE 
    mh.depth <= 1
ORDER BY 
    mh.production_year DESC, mh.title;
