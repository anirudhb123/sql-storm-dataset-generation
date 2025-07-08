
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        c.name AS company_name,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, c.name
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        company_name,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 3 
)
SELECT 
    tm.production_year,
    LISTAGG(tm.title || ' (' || tm.company_name || ')', ', ') WITHIN GROUP (ORDER BY tm.title) AS top_movies,
    AVG(tm.cast_count) AS average_cast_count
FROM 
    TopMovies tm
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year DESC;
