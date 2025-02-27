WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_in_year
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
), 

CastWithRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.role_id) AS role_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.name IS NOT NULL
),

KeywordUsage AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    cr.role_count,
    cr.roles,
    COALESCE(cd.company_name, 'Unknown') AS company_name,
    COALESCE(cd.company_type, 'N/A') AS company_type,
    ku.keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CastWithRoles cr ON rm.id = cr.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.id = cd.movie_id
LEFT JOIN 
    KeywordUsage ku ON rm.id = ku.movie_id
WHERE 
    rm.rank_in_year <= 5
    AND (ku.keyword_count IS NULL OR ku.keyword_count >= 2)
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
