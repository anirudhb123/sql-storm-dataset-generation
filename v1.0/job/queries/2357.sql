WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn,
        COUNT(ci.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighCastMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rn <= 5
),
CompanyMovieInfo AS (
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
    hm.title,
    hm.production_year,
    hm.total_cast,
    COALESCE(cmi.company_count, 0) AS company_count,
    COALESCE(cmi.company_names, 'No companies') AS company_names
FROM 
    HighCastMovies hm
LEFT JOIN 
    CompanyMovieInfo cmi ON hm.movie_id = cmi.movie_id
WHERE 
    hm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    hm.production_year DESC, hm.total_cast DESC;
