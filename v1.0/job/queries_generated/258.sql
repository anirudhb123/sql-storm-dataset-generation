WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(cn.name ORDER BY cn.name SEPARATOR ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    pm.title,
    COALESCE(pm.cast_count, 0) AS number_of_cast,
    COALESCE(cd.companies, 'No companies listed') AS production_companies
FROM 
    PopularMovies pm
LEFT JOIN 
    CompanyDetails cd ON pm.movie_id = cd.movie_id
ORDER BY 
    pm.production_year DESC, 
    pm.cast_count DESC;
