WITH RankedMovies AS (
    SELECT 
        a.title AS MovieTitle,
        a.production_year AS Year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS YearRank,
        COUNT(c.person_id) AS CastCount
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        a.id, a.title, a.production_year
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(*) AS CompanyCount
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
CastRoles AS (
    SELECT 
        c.movie_id,
        r.role AS RoleName,
        COUNT(c.id) AS RoleCount
    FROM 
        cast_info c
    INNER JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        k.keyword AS Keyword,
        COUNT(mk.id) AS KeywordCount
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
)

SELECT 
    rm.MovieTitle,
    rm.Year,
    rm.CastCount,
    COALESCE(mcc.CompanyCount, 0) AS CompanyCount,
    COALESCE(cr.RoleCount, 0) AS RoleCount,
    kc.Keyword,
    kc.KeywordCount
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovieCounts mcc ON rm.Year = EXTRACT(YEAR FROM rm.Year)
LEFT JOIN 
    CastRoles cr ON rm.Year = cr.movie_id
LEFT JOIN 
    KeywordCounts kc ON rm.Year = kc.movie_id
WHERE 
    rm.YearRank <= 10
ORDER BY 
    rm.Year DESC, rm.CastCount DESC;
