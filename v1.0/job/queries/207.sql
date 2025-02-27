WITH movie_cast AS (
    SELECT 
        ci.movie_id,
        p.name AS actor_name,
        COUNT(DISTINCT ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        ci.movie_id, p.name
), 
movie_info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS infos
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info LIKE '%Award%'
    GROUP BY 
        mi.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(mc.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(mc.role_count, 0) AS total_roles,
    COALESCE(mid.infos, 'No Info Available') AS awards_info
FROM 
    aka_title m
LEFT JOIN 
    movie_cast mc ON m.id = mc.movie_id
LEFT JOIN 
    movie_info_details mid ON m.id = mid.movie_id
WHERE 
    m.production_year >= 2000
    AND (m.note IS NULL OR m.note NOT LIKE '%unreleased%')
ORDER BY 
    m.production_year DESC, 
    total_roles DESC
LIMIT 50;
