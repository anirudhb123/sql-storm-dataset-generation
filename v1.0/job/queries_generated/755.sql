WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        MAX(c.name) AS max_company_name
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mwk.title,
    mwk.production_year,
    mwk.keywords,
    COALESCE(cs.company_count, 0) AS company_count,
    cs.max_company_name
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    CompanyStats cs ON mwk.movie_id = cs.movie_id
WHERE 
    mwk.production_year >= 2000
ORDER BY 
    mwk.production_year DESC, company_count DESC;
