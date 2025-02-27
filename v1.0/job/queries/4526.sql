WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieCompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    COALESCE(cr.role_count, 0) AS total_roles,
    mcc.company_count,
    CASE 
        WHEN rm.title_rank <= 5 THEN 'Top 5 in Year'
        ELSE 'Other'
    END AS rank_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastRoles cr ON rm.movie_id = cr.movie_id
LEFT JOIN 
    MovieCompanyCounts mcc ON rm.movie_id = mcc.movie_id
WHERE 
    (rm.production_year > 2000 AND mcc.company_count > 1) 
    OR (rm.production_year <= 2000 AND COALESCE(cr.role_count, 0) > 0)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
