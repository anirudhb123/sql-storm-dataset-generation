WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        ARRAY_AGG(DISTINCT g.kind ORDER BY g.kind) AS genres,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.id) DESC) AS rank
    FROM
        aka_title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_type g ON mc.company_type_id = g.id
    LEFT JOIN
        complete_cast c ON t.id = c.movie_id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        company_count,
        genres
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_count,
    tm.genres,
    ARRAY_AGG(DISTINCT a.name ORDER BY a.name) AS actors
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id) 
JOIN 
    aka_name a ON ci.person_id = a.person_id
GROUP BY 
    tm.title, tm.production_year, tm.company_count, tm.genres
ORDER BY 
    tm.company_count DESC;
