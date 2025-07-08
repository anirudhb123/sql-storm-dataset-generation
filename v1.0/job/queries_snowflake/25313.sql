
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        LISTAGG(CONCAT(a.name, ' (', rt.role, ')'), ', ') WITHIN GROUP (ORDER BY a.name) AS full_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        title t
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        role_type rt ON rt.id = ci.role_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        full_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.production_year,
    COUNT(tm.movie_id) AS movie_count,
    LISTAGG(tm.title, '; ') WITHIN GROUP (ORDER BY tm.title) AS top_movies,
    LISTAGG(tm.full_cast, '; ') WITHIN GROUP (ORDER BY tm.full_cast) AS all_casts
FROM 
    TopMovies tm
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year DESC;
