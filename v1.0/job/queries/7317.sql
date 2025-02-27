WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        companies 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.cast_count, 
    tm.companies, 
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.companies
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
