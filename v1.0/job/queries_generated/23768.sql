WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT 
        ci.person_id, 
        ci.movie_id,
        COUNT(*) OVER (PARTITION BY ci.person_id) AS total_roles
    FROM 
        cast_info ci
    WHERE 
        ci.person_role_id IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    r.title,
    r.production_year,
    COALESCE(fc.person_id, 0) AS person_id,
    COALESCE(fc.total_roles, 0) AS total_roles,
    COALESCE(mc.company_count, 0) AS company_count,
    mc.company_names,
    CASE 
        WHEN mc.company_count IS NULL THEN 'No Companies'
        ELSE 'Has Companies'
    END AS company_status
FROM 
    RankedMovies r
LEFT JOIN 
    FilteredCast fc ON EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = r.id AND ci.person_id = fc.person_id
    )
LEFT JOIN 
    MovieCompanies mc ON r.id = mc.movie_id
WHERE 
    r.rank <= 5
    AND (r.production_year < 2000 OR r.production_year IS NULL)
ORDER BY 
    r.production_year DESC, 
    r.title;
