
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  
    UNION ALL
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_info_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT mc.company_type_id) AS company_types_count
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
    COALESCE(c.total_cast, 0) AS total_cast,
    COALESCE(c.cast_names, '') AS cast_names,
    COALESCE(ci.companies, ARRAY[]::TEXT[]) AS companies,
    COALESCE(ci.company_types_count, 0) AS company_types_count,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COALESCE(c.total_cast, 0) DESC) AS rank_within_year
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info_summary c ON mh.movie_id = c.movie_id
LEFT JOIN 
    company_info ci ON mh.movie_id = ci.movie_id
ORDER BY 
    mh.production_year DESC, COALESCE(c.total_cast, 0) DESC;
