WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
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
        STRING_AGG(CASE WHEN ct.kind IS NOT NULL THEN c.name END, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(ci.companies, 'No companies') AS companies,
    (SELECT COUNT(DISTINCT ci2.person_id) 
     FROM cast_info ci2 
     WHERE ci2.movie_id = rm.id) AS num_cast_members
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.id = mk.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.id = ci.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
