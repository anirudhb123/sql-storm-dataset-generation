WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(c.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyMovies AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(c.name, ', ') AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    GROUP BY 
        m.movie_id
),
FilteredMovies AS (
    SELECT 
        r.title, 
        r.production_year, 
        r.cast_count, 
        cm.companies
    FROM 
        RankedMovies r
    LEFT JOIN 
        CompanyMovies cm ON r.title = cm.movie_id
    WHERE 
        r.rank_within_year = 1
    AND 
        r.production_year >= 2000
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    COALESCE(fm.companies, 'No Companies') AS companies
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
