WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cmp.company_name, 'Independent') AS production_company,
    tm.total_cast,
    CASE 
        WHEN tm.total_cast > 10 THEN 'Large Cast'
        WHEN tm.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyMovies cmp ON tm.title = (SELECT title FROM aka_title WHERE id = cmp.movie_id)
LEFT JOIN 
    movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    tm.title, tm.production_year, cmp.company_name, tm.total_cast
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;
