WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        c.movie_id,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(mi.info, ', ') AS movie_infos
    FROM 
        movie_info m
    JOIN 
        movie_info_idx mi ON m.id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cr.role_name,
    COALESCE(cr.role_count, 0) AS role_count,
    mi.movie_infos
FROM 
    RankedTitles rt
LEFT JOIN 
    CastRoles cr ON rt.title_id = cr.movie_id AND cr.role_name IS NOT NULL
LEFT JOIN 
    MovieInfo mi ON rt.title_id = mi.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
