WITH movie_info_agg AS (
    SELECT 
        mi.movie_id,
        COUNT(mi.info) AS info_count,
        MAX(mi.info) AS latest_info,
        MIN(mi.info) AS earliest_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
actor_roles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.person_role_id = r.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    t.id AS title_id,
    t.title,
    t.production_year,
    COALESCE(mia.info_count, 0) AS info_count,
    COALESCE(mia.latest_info, 'N/A') AS latest_info,
    COALESCE(mia.earliest_info, 'N/A') AS earliest_info,
    COALESCE(ar.actor_count, 0) AS actor_count,
    COALESCE(ar.roles, 'No roles') AS roles
FROM 
    title t
LEFT JOIN 
    movie_info_agg mia ON t.id = mia.movie_id
LEFT JOIN 
    actor_roles ar ON t.id = ar.movie_id
WHERE 
    (t.production_year >= 2000 OR t.title ILIKE '%award%')
    AND (t.kind_id IS NOT NULL)
ORDER BY 
    t.production_year DESC,
    actor_count DESC
LIMIT 50;
