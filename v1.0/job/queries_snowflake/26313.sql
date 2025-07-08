
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        m.name AS company_name, 
        k.keyword 
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 
        AND m.country_code = 'USA'
        AND k.keyword LIKE '%action%'
),
MovieRankings AS (
    SELECT 
        title, 
        production_year, 
        company_name, 
        keyword,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY title) AS rank
    FROM 
        RankedMovies
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        company_name, 
        keyword 
    FROM 
        MovieRankings 
    WHERE 
        rank <= 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.company_name, 
    tm.keyword, 
    COUNT(c.id) AS cast_count 
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info c ON tm.title = c.title
GROUP BY 
    tm.title, 
    tm.production_year, 
    tm.company_name, 
    tm.keyword
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
