WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        title t
    JOIN 
        aka_title ak ON t.id = ak.movie_id
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id
), 
CompanyStats AS (
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
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.aka_names,
    cs.company_count,
    cs.company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
