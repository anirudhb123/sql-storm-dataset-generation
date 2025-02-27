WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 5  
),

ranked_cast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
),

company_summary AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS total_companies,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id 
),

movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(CASE 
            WHEN it.info = 'plot' THEN mi.info
            ELSE NULL
        END, '; ') AS plots,
        STRING_AGG(CASE 
            WHEN it.info = 'rating' THEN mi.info
            ELSE NULL
        END, '; ') AS ratings
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ARRAY_AGG(DISTINCT rc.actor_name) AS actor_names,
    cs.total_companies,
    cs.company_names,
    mis.plots,
    mis.ratings
FROM 
    movie_hierarchy mh
LEFT JOIN 
    ranked_cast rc ON mh.movie_id = rc.movie_id
LEFT JOIN 
    company_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movie_info_summary mis ON mh.movie_id = mis.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, cs.total_companies, cs.company_names, mis.plots, mis.ratings
HAVING 
    COUNT(rc.actor_name) > 2 OR cs.total_companies IS NULL 
ORDER BY 
    mh.production_year DESC, mh.title
LIMIT 10;