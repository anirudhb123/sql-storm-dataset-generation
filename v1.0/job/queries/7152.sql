WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    WHERE t.production_year IS NOT NULL AND c.country_code = 'USA'
),
TopMovies AS (
    SELECT title, production_year, company_name, keyword
    FROM RankedMovies
    WHERE rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_name,
    STRING_AGG(tm.keyword, ', ') AS keywords
FROM TopMovies tm
GROUP BY tm.title, tm.production_year, tm.company_name
ORDER BY tm.production_year DESC, tm.title;
