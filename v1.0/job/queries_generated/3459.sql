WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 
movie_cast AS (
    SELECT 
        mc.movie_id,
        a.name AS actor_name,
        rt.title,
        rt.production_year
    FROM 
        movie_companies mc
    JOIN 
        aka_title at ON mc.movie_id = at.id
    LEFT JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        ranked_titles rt ON at.id = rt.title_id
), 
movie_info_filtered AS (
    SELECT 
        movie_id,
        STRING_AGG(info, ', ') AS all_info
    FROM 
        movie_info
    WHERE 
        info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Rating%' AND LENGTH(info) > 0)
    GROUP BY 
        movie_id
)
SELECT 
    mc.movie_id,
    mc.title,
    mc.production_year,
    mc.actor_name,
    mii.all_info,
    COUNT(DISTINCT mc.actor_name) OVER (PARTITION BY mc.movie_id) AS actor_count,
    COALESCE(mii.all_info, 'No Info Available') AS formatted_info
FROM 
    movie_cast mc
LEFT JOIN 
    movie_info_filtered mii ON mc.movie_id = mii.movie_id
WHERE 
    mc.production_year >= 2000
ORDER BY 
    mc.production_year DESC, 
    actor_count DESC, 
    mc.title;
