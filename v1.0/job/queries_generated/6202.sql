WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        c.name AS company_name,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        company_name,
        keyword
    FROM 
        RankedMovies
    WHERE 
        rn = 1
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_name,
    COUNT(*) AS keyword_count
FROM 
    TopMovies tm
JOIN 
    aka_name an ON tm.title ILIKE '%' || an.name || '%'
GROUP BY 
    tm.title, tm.production_year, tm.company_name
ORDER BY 
    tm.production_year DESC, keyword_count DESC
LIMIT 50;
