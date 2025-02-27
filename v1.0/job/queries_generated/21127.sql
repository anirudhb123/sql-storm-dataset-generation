WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(k.keyword) FILTER (WHERE k.keyword LIKE '%action%') OVER (PARTITION BY t.id) AS action_keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
title_with_cast AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        mc.actor_count,
        mc.actor_names,
        rt.action_keyword_count,
        CASE 
            WHEN mc.actor_count IS NULL THEN 'No Actors'
            WHEN mc.actor_count > 10 THEN 'Large Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM 
        ranked_titles rt
    LEFT JOIN 
        movie_cast mc ON rt.title_id = mc.movie_id
)
SELECT 
    twc.title,
    twc.production_year,
    twc.actor_count,
    twc.actor_names,
    twc.action_keyword_count,
    twc.cast_size
FROM 
    title_with_cast twc
WHERE 
    twc.action_keyword_count > 0
    OR twc.cast_size = 'Large Cast'
ORDER BY 
    twc.production_year DESC,
    twc.title_rank ASC NULLS LAST
LIMIT 50
UNION ALL
SELECT 
    'Total Titles' AS title,
    NULL AS production_year,
    COUNT(*) AS actor_count,
    STRING_AGG(twc.title, ', ') AS actor_names,
    NULL AS action_keyword_count,
    NULL AS cast_size
FROM 
    title_with_cast twc;
