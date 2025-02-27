WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
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
        rank <= 3
),
Actors AS (
    SELECT 
        ak.name AS actor_name, 
        tm.title, 
        tm.production_year
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        TopMovies tm ON c.movie_id = (SELECT movie_id FROM complete_cast WHERE subject_id = ak.person_id LIMIT 1)
)
SELECT 
    tm.title, 
    tm.production_year, 
    STRING_AGG(DISTINCT a.actor_name, ', ') AS actor_names
FROM 
    TopMovies tm
LEFT JOIN 
    Actors a ON tm.title = a.title AND tm.production_year = a.production_year
GROUP BY 
    tm.title, 
    tm.production_year
ORDER BY 
    tm.production_year DESC, 
    tm.title;
