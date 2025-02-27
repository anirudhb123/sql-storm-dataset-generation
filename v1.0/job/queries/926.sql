WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),

CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)

SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    ci.company_name,
    ci.company_type,
    ci.company_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
