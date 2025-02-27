WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.country_code) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(cm.company_count, 0) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyMovies cm ON rm.title = (SELECT mt.title FROM aka_title mt WHERE mt.id = rm.title_id)
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    title,
    production_year,
    cast_count,
    company_count,
    CASE 
        WHEN cast_count > 0 THEN ROUND(company_count::decimal / cast_count, 2)
        ELSE NULL 
    END AS company_per_cast_ratio
FROM 
    FilteredMovies
WHERE 
    production_year IS NOT NULL
ORDER BY 
    production_year DESC, 
    cast_count DESC;
