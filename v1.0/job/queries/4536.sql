
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    cm.companies,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 10;
