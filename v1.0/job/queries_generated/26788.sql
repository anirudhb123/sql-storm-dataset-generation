WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        p.name AS person_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS movie_rank
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name p ON p.person_id = ci.person_id
    JOIN 
        role_type r ON r.id = ci.role_id
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT 
    rm.movie_title,
    rm.production_year,
    STRING_AGG(rm.person_name || ' (' || rm.role_name || ')', ', ') AS cast_details
FROM 
    RankedMovies rm
WHERE 
    rm.movie_rank <= 5
GROUP BY 
    rm.movie_title, rm.production_year
ORDER BY 
    rm.production_year DESC;

This SQL query aims to benchmark string processing by generating a list of movies along with the cast details. It uses Common Table Expressions (CTEs) to create a ranking of movies based on the production year and aggregates the character data of the cast into a single string for each movie. The output will pull only the top 5 movies per production year, enhancing the performance metrics of string processing capabilities through `STRING_AGG()`.
