WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        a.production_year IS NOT NULL
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.role,
    mcd.company_count,
    mcd.company_names,
    km.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCompanyDetails mcd ON rm.id = mcd.movie_id
LEFT JOIN 
    KeywordMovies km ON rm.id = km.movie_id
WHERE 
    rm.rn = 1
ORDER BY 
    rm.production_year DESC,
    mcd.company_count DESC
LIMIT 10;
