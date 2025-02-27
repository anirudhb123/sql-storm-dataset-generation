
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        n.name AS cast_name,
        r.role AS role,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.title) AS rn
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        name n ON ci.person_id = n.id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        title t ON a.id = t.id
    WHERE 
        t.production_year >= 2000
),
TopMovies AS (
    SELECT 
        movie_title,
        cast_name,
        role,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
)
SELECT 
    production_year,
    COUNT(movie_title) AS movie_count,
    STRING_AGG(cast_name || ' (' || role || ')', ', ') AS cast_details
FROM 
    TopMovies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
