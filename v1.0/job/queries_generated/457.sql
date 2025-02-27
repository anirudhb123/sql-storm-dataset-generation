WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL 
    GROUP BY 
        t.title, t.production_year
),

TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_per_year <= 5
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(STRING_AGG(DISTINCT an.name, ', '), 'No Cast') AS actors,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    (SELECT COUNT(DISTINCT m.id)
     FROM movie_companies m
     WHERE m.movie_id = t.id) AS company_count
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year)
JOIN 
    aka_title t ON tm.title = t.title AND tm.production_year = t.production_year
WHERE 
    tm.production_year BETWEEN 2000 AND 2023
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, COUNT(DISTINCT an.name) DESC;
