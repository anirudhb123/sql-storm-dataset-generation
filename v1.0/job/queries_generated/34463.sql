WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.movie_id AS root_movie_id,
        mt.linked_movie_id,
        1 AS level
    FROM 
        movie_link mt
    WHERE 
        mt.link_type_id = (SELECT id FROM link_type WHERE link = 'is sequel of')
    
    UNION ALL
    
    SELECT 
        mh.root_movie_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'is sequel of')
),
all_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year) AS year_rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
cast_performance AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.id) AS cast_count,
        SUM(CASE 
            WHEN rt.role = 'Lead' THEN 1 
            ELSE 0 
        END) AS lead_roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
movie_analysis AS (
    SELECT 
        am.movie_id,
        am.title,
        am.production_year,
        COALESCE(cp.cast_count, 0) AS total_cast,
        COALESCE(cp.lead_roles, 0) AS lead_roles,
        (SELECT COUNT(DISTINCT linked_movie_id) FROM movie_hierarchy mh WHERE mh.root_movie_id = am.movie_id) AS sequel_count
    FROM 
        all_movies am
    LEFT JOIN 
        cast_performance cp ON am.movie_id = cp.movie_id
)
SELECT 
    ma.title,
    ma.production_year,
    ma.total_cast,
    ma.lead_roles,
    ma.sequel_count,
    CASE 
        WHEN ma.total_cast > 0 THEN CAST(ma.lead_roles AS FLOAT) / ma.total_cast 
        ELSE NULL 
    END AS lead_ratio,
    (SELECT MAX(year_rank) FROM all_movies WHERE production_year = ma.production_year) AS max_year_rank,
    STRING_AGG(DISTINCT k.keyword, ', ') AS all_keywords
FROM 
    movie_analysis ma
LEFT JOIN 
    movie_keyword mk ON ma.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ma.production_year >= 2000
GROUP BY 
    ma.movie_id, ma.title, ma.production_year, ma.total_cast, ma.lead_roles, ma.sequel_count
ORDER BY 
    ma.production_year DESC, ma.lead_ratio DESC NULLS LAST;
