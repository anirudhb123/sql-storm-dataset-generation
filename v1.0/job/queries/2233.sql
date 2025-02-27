WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast 
    FROM 
        aka_title t 
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id 
    GROUP BY 
        t.id, t.title, t.production_year
),
GenreKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        mk.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id, 
        STRING_AGG(cn.name, ', ') AS companies, 
        STRING_AGG(ct.kind, ', ') AS company_types 
    FROM 
        movie_companies mc 
    JOIN 
        company_name cn ON mc.company_id = cn.id 
    JOIN 
        company_type ct ON mc.company_type_id = ct.id 
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    rm.rank_by_cast, 
    COALESCE(gi.keywords, 'No Keywords') AS keywords, 
    COALESCE(ci.companies, 'No Companies') AS companies, 
    COALESCE(ci.company_types, 'N/A') AS company_types 
FROM 
    RankedMovies rm 
LEFT JOIN 
    GenreKeywords gi ON rm.movie_id = gi.movie_id 
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id 
WHERE 
    rm.rank_by_cast <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.rank_by_cast;
