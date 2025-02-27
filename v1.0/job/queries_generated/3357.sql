WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY a.production_year) AS total_titles
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        a.production_year IS NOT NULL
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
CastRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.role_id) AS role_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.rn,
    rm.total_titles,
    COALESCE(cmc.company_count, 0) AS company_count,
    COALESCE(cr.role_count, 0) AS role_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovieCount cmc ON rm.movie_id = cmc.movie_id
LEFT JOIN 
    CastRoles cr ON rm.movie_id = cr.movie_id
WHERE 
    rm.rn = 1 OR (rm.rn = 2 AND rm.total_titles > 2)
ORDER BY 
    rm.production_year DESC, rm.title;
