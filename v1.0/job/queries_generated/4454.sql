WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv movie'))
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieWithCast AS (
    SELECT 
        rc.movie_id,
        COALESCE(SUM(CASE WHEN ci.person_role_id = 1 THEN 1 ELSE 0 END), 0) AS lead_actor_count
    FROM 
        complete_cast rc
    LEFT JOIN 
        cast_info ci ON rc.movie_id = ci.movie_id
    GROUP BY 
        rc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mc.total_companies, 0) AS company_count,
    COALESCE(mwc.lead_actor_count, 0) AS lead_actor_count,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MovieWithCast mwc ON rm.movie_id = mwc.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, rm.title;
