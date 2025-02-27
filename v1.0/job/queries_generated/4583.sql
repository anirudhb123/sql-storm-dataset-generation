WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.movie_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
NullHandled AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(r.rank, 9999) AS rank
    FROM 
        RankedMovies r
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MoviesWithCompanyCount AS (
    SELECT 
        nm.movie_id,
        nm.title,
        nm.production_year,
        cm.company_count
    FROM 
        NullHandled nm
    LEFT JOIN 
        CompanyMovieCount cm ON nm.movie_id = cm.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.company_count,
    CASE 
        WHEN m.company_count IS NULL THEN 'No Companies'
        ELSE 'Companies Present'
    END AS company_status
FROM 
    MoviesWithCompanyCount m
WHERE 
    m.rank < 5
ORDER BY 
    m.production_year DESC, 
    m.company_count DESC NULLS LAST;
