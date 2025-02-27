
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  
    
    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_members
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.company_type_id IS NOT NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cs.cast_count, 0) AS total_cast,
    COALESCE(cs.cast_members, 'No Cast') AS cast_list,
    COALESCE(ks.keyword_count, 0) AS total_keywords,
    COALESCE(ci.companies, ARRAY[NULL]) AS companies_involved,
    mh.level AS hierarchy_level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
LEFT JOIN 
    company_info ci ON mh.movie_id = ci.movie_id
ORDER BY 
    mh.production_year DESC, mh.level, mh.title;
