WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        '' AS parent_title
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL 
    
    UNION ALL
    
    SELECT 
        ep.id AS movie_id,
        ep.title AS movie_title,
        ep.production_year,
        mh.level + 1 AS level,
        mh.movie_title AS parent_title
    FROM 
        aka_title ep
    JOIN 
        movie_hierarchy mh ON ep.episode_of_id = mh.movie_id
),
cast_stats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT cn.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    GROUP BY 
        ci.movie_id
),
company_stats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
movie_tags AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.level,
    mh.parent_title,
    cs.total_cast,
    cs.cast_names,
    co.total_companies,
    co.company_names,
    mt.keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_stats cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    company_stats co ON mh.movie_id = co.movie_id
LEFT JOIN 
    movie_tags mt ON mh.movie_id = mt.movie_id
WHERE 
    (mh.production_year >= 2000 OR mh.level = 1) 
    AND (co.total_companies IS NULL OR co.total_companies > 2)
ORDER BY 
    mh.production_year DESC, mh.level ASC, mh.movie_title;
