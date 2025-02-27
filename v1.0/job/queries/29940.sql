WITH ranked_titles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
),
title_keywords AS (
    SELECT 
        at.id AS title_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.id
),
movie_info_data AS (
    SELECT 
        mi.movie_id,
        ARRAY_AGG(DISTINCT CONCAT(it.info, ': ', mi.info)) AS movie_info_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    rt.actor_name,
    rt.year_rank,
    tk.keywords,
    mi.movie_info_details
FROM 
    ranked_titles rt
LEFT JOIN 
    title_keywords tk ON rt.title_id = tk.title_id
LEFT JOIN 
    movie_info_data mi ON rt.title_id = mi.movie_id
WHERE 
    rt.production_year >= 2000
ORDER BY 
    rt.production_year DESC, rt.year_rank
LIMIT 100;
