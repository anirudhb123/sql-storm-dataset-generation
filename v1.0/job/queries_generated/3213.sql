WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_title, 
    rm.production_year, 
    rm.cast_count, 
    cd.company_count,
    cd.company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_title = (SELECT title FROM aka_title WHERE id = rm.movie_title LIMIT 1)
WHERE 
    rm.rank <= 5 OR cd.company_count IS NULL
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
