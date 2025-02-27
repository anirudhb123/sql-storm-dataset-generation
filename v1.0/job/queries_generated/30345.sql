WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY[m.id] AS path,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.path || m.id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
title_keywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
cast_info_with_roles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
company_counts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    coalesce(tk.keywords, 'No Keywords') AS keywords,
    cc.company_count,
    STRING_AGG(cir.actor_name || ' (' || cir.role_name || ')', ', ') AS cast_details
FROM 
    movie_hierarchy mh
LEFT JOIN 
    title_keywords tk ON mh.movie_id = tk.movie_id
LEFT JOIN 
    company_counts cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info_with_roles cir ON mh.movie_id = cir.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, cc.company_count
ORDER BY 
    mh.production_year DESC, mh.title;
