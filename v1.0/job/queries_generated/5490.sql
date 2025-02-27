WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rank
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        rp.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rp ON ci.role_id = rp.id
    GROUP BY 
        ci.movie_id, ci.person_id, rp.role
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
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
    rm.keyword,
    ci.person_id,
    ci.role,
    ci.role_count,
    cs.company_count
FROM 
    RankedMovies rm
JOIN 
    CastInfoWithRoles ci ON rm.movie_id = ci.movie_id
JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, ci.role_count DESC;
