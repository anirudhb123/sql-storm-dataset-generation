WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cd.companies, 'No companies') AS companies,
    COALESCE(k.keywords, 'No keywords') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    (SELECT 
         mk.movie_id, 
         STRING_AGG(DISTINCT k.keyword, ', ') AS keywords 
     FROM 
         movie_keyword mk 
     JOIN 
         keyword k ON mk.keyword_id = k.id 
     GROUP BY 
         mk.movie_id) k ON tm.title = k.movie_id
LEFT JOIN 
    CompanyDetails cd ON tm.title = cd.movie_id
WHERE 
    tm.production_year > 2000
ORDER BY 
    tm.production_year DESC, 
    tm.title;
