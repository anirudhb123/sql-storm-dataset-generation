WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
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
        year_rank <= 5
),
MovieInfo AS (
    SELECT 
        m.title, 
        GROUP_CONCAT(mi.info SEPARATOR ', ') AS movie_info
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_info mi ON mi.movie_id = (SELECT id FROM aka_title WHERE title = m.title AND production_year = m.production_year LIMIT 1)
    GROUP BY 
        m.title
)
SELECT 
    tm.title, 
    tm.production_year, 
    mi.movie_info, 
    COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No actors') AS actor_names
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    cast_info ci ON cc.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    MovieInfo mi ON tm.title = mi.title
GROUP BY 
    tm.title, tm.production_year, mi.movie_info
HAVING 
    (COUNT(DISTINCT ak.name) > 0 OR mi.movie_info IS NOT NULL)
ORDER BY 
    tm.production_year DESC, 
    COUNT(DISTINCT ak.name) DESC;
