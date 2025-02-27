WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RANDOM()) AS random_rank,
        COUNT(DISTINCT cm.company_id) OVER (PARTITION BY t.id) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.random_rank,
        rm.company_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.random_rank <= 10 AND rm.company_count > 1
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        string_agg(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON rt.id = ci.role_id
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT
        fm.movie_id,
        fm.title,
        fm.production_year,
        cr.roles,
        CASE 
            WHEN fm.company_count IS NULL THEN 'No Companies' 
            ELSE 'Has Companies' 
        END AS company_status
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        CastRoles cr ON cr.movie_id = fm.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.roles,
    md.company_status,
    COALESCE(NULLIF(md.roles, ''), 'Unknown Role') AS safe_roles,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN 
        (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = md.movie_id)
    ) AS cast_count
FROM 
    MovieDetails md
WHERE 
    md.company_status = 'Has Companies'
ORDER BY 
    md.production_year DESC, 
    md.title ASC
LIMIT 25;
