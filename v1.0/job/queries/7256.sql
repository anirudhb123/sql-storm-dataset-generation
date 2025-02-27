
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    INNER JOIN 
        complete_cast cc ON t.id = cc.movie_id
    INNER JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
), TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    a.name AS actor_name,
    COUNT(DISTINCT c.person_id) AS total_movies_by_actor,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tm.movie_id, tm.movie_title, tm.production_year, a.name
ORDER BY 
    tm.production_year DESC, total_movies_by_actor DESC;
