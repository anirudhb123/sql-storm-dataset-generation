
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT na.name ORDER BY na.name) AS cast_names
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name na ON c.person_id = na.person_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        total_cast,
        cast_names,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.rank,
    LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS cast_details
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    aka_name cn ON ci.person_id = cn.person_id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.movie_title, tm.production_year, tm.total_cast, tm.rank
ORDER BY 
    tm.rank;
