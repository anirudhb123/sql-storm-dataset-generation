WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
), CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
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
    rm.cast_count,
    COALESCE(ci.companies, 'No companies') AS production_companies,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.title = (SELECT t.title FROM aka_title t WHERE t.id = ci.movie_id)
LEFT JOIN 
    MovieKeywords mk ON rm.title = (SELECT t.title FROM aka_title t WHERE t.id = mk.movie_id)
WHERE 
    rm.rank <= 3
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
