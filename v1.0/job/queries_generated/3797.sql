WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10 
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(c.name, 'Unknown') AS company_name,
    SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tm.title, tm.production_year, company_name
HAVING 
    COUNT(DISTINCT k.id) >= 1
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
