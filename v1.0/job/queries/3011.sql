WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
)
SELECT 
    fm.title, 
    fm.production_year, 
    fm.cast_count, 
    ci.company_name,
    ci.company_type
FROM 
    FilteredMovies fm
LEFT JOIN 
    CompanyInfo ci ON ci.movie_id = (SELECT mc.movie_id FROM movie_companies mc WHERE mc.movie_id = fm.production_year LIMIT 1)
WHERE 
    ci.company_name IS NOT NULL
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
