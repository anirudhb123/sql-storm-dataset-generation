WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT ca.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank 
    FROM 
        aka_title a 
    LEFT JOIN 
        cast_info ca ON a.id = ca.movie_id 
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.num_cast 
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rank <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
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
    tm.title,
    tm.production_year,
    COALESCE(ci.company_names, 'No Companies') AS company_names,
    COALESCE(ci.company_types, 'No Types') AS company_types,
    tm.num_cast 
FROM 
    TopMovies tm 
LEFT JOIN 
    CompanyInfo ci ON tm.movie_id = ci.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.num_cast DESC;
