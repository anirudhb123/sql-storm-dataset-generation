WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT COALESCE(a.name, 'Unknown'), ', ') AS actors
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyMovies AS (
    SELECT 
        m.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actors,
    cm.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 50;
