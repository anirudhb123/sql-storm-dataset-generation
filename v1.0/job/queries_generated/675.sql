WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MostCast AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank = 1
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mm.title,
    mm.production_year,
    cmi.company_count,
    CASE 
        WHEN cmi.company_count IS NULL THEN 'No Companies'
        ELSE cmi.company_names 
    END AS company_names
FROM 
    MostCast mm
LEFT JOIN 
    CompanyMovieInfo cmi ON mm.movie_id = cmi.movie_id
WHERE 
    mm.production_year >= 2000
ORDER BY 
    mm.production_year DESC, 
    cmi.company_count DESC NULLS LAST;
