WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyMovieInfo AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
        m.info_type_id,
        m.info
    FROM 
        movie_companies m
    LEFT JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        m.movie_id, m.info_type_id, m.info
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    cm.companies,
    mi.info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.production_year = mi.movie_id
LEFT JOIN 
    CompanyMovieInfo cm ON cm.movie_id = (SELECT movie_id FROM complete_cast cc WHERE cc.id = (SELECT MIN(id) FROM complete_cast WHERE movie_id = tm.production_year))
WHERE 
    mi.info IS NOT NULL OR cm.companies IS NOT NULL
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
