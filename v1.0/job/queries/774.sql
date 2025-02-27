WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        cast_count 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    ci.companies,
    ci.company_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    CompanyInfo ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = fm.title AND production_year = fm.production_year LIMIT 1)
WHERE 
    fm.production_year >= 2000
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
