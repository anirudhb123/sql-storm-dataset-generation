WITH RankedMovies AS (
    SELECT 
        a.title,
        t.production_year,
        a.kind_id,
        COUNT(ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT p.name) AS cast_names
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    JOIN 
        cast_info ci ON a.movie_id = ci.movie_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        a.title, t.production_year, a.kind_id
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code = 'USA'
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    cmc.company_count,
    rm.cast_names
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovieCounts cmc ON rm.title = (SELECT title FROM aka_title WHERE movie_id = cmc.movie_id LIMIT 1)
ORDER BY 
    rm.production_year DESC,
    rm.cast_count DESC
LIMIT 100;
