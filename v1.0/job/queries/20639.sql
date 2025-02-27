WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_role_count AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        ranked_titles rt ON ci.movie_id = rt.title_id
    GROUP BY 
        ci.person_id
),
movie_info_filtered AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_aggregation
    FROM 
        movie_info mi
    WHERE 
        mi.info IS NOT NULL
        AND EXISTS (
            SELECT 1
            FROM movie_keyword mk
            WHERE mk.movie_id = mi.movie_id
            AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Action%')
        )
    GROUP BY 
        mi.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    ac.role_count,
    mif.info_aggregation,
    CASE 
        WHEN ac.role_count > 5 THEN 'Veteran Actor'
        WHEN ac.role_count BETWEEN 2 AND 5 THEN 'Experienced Actor'
        ELSE 'Novice Actor'
    END AS actor_experience_level
FROM 
    ranked_titles t
LEFT JOIN 
    cast_info ci ON t.title_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    actor_role_count ac ON ac.person_id = ci.person_id
LEFT JOIN 
    movie_info_filtered mif ON mif.movie_id = t.title_id
WHERE 
    t.production_year < 2000
    AND (a.name IS NOT NULL OR a.name IS NULL) 
    AND (mif.info_aggregation IS NOT NULL OR EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = t.title_id
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
    ))
ORDER BY 
    t.production_year DESC, 
    a.name
LIMIT 100;