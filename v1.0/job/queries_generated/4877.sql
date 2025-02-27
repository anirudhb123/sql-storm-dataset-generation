WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS ranking,
        COALESCE(k.keyword, 'No Keyword') AS keyword
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
),
CastAndRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cr.cast_count, 0) AS total_cast,
    COALESCE(cr.roles, 'No Roles') AS roles,
    COALESCE(mcd.company_count, 0) AS total_companies,
    COALESCE(mcd.company_names, 'No Companies') AS companies,
    rm.keyword
FROM 
    RankedMovies rm
LEFT JOIN 
    CastAndRoles cr ON rm.movie_id = cr.movie_id
LEFT JOIN 
    MovieCompanyDetails mcd ON rm.movie_id = mcd.movie_id
WHERE 
    rm.ranking <= 3
ORDER BY 
    rm.production_year DESC, rm.title;
