WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ca ON t.id = ca.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(rm.cast_count, 0) AS total_cast,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(ci.company_name, 'No Company') AS production_company,
    ci.company_type,
    ci.total_companies,
    CASE 
        WHEN rm.cast_count IS NULL THEN 'Not Available'
        ELSE 'Available'
    END AS cast_availability
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.title = mk.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.title = ci.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
