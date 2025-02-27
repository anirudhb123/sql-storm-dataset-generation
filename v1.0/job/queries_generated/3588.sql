WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        m.movie_id
),
FinalReport AS (
    SELECT 
        fm.movie_title,
        fm.production_year,
        fm.cast_count,
        ci.companies
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        CompanyInfo ci ON fm.movie_title = (SELECT title FROM aka_title WHERE id = fm.movie_title)
)
SELECT 
    f.movie_title,
    f.production_year,
    COALESCE(f.cast_count, 0) AS total_cast,
    COALESCE(f.companies, 'No Companies') AS involved_companies
FROM 
    FinalReport f
WHERE 
    f.production_year >= 2000
ORDER BY 
    f.production_year DESC, f.total_cast DESC;
