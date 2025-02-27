WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COALESCE(CNT.company_count, 0) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN (
        SELECT 
            movie_id, COUNT(DISTINCT company_id) AS company_count
        FROM 
            movie_companies
        GROUP BY 
            movie_id
    ) AS CNT ON mc.movie_id = CNT.movie_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    cs.company_count,
    cs.companies,
    ROW_NUMBER() OVER (ORDER BY rm.production_year DESC, rm.cast_count DESC) AS overall_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.rank <= 5 
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 10;
