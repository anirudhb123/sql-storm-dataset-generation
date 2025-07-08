
WITH RecursiveMovie AS (
    SELECT 
        movies.id AS movie_id,
        movies.title,
        movies.production_year,
        COUNT(DISTINCT actors.person_id) AS actor_count
    FROM 
        aka_title movies
    JOIN 
        movie_companies mc ON movies.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON movies.id = ci.movie_id
    JOIN 
        aka_name actors ON ci.person_id = actors.person_id
    GROUP BY 
        movies.id, movies.title, movies.production_year
), 
YearlyProduction AS (
    SELECT 
        production_year,
        SUM(actor_count) AS total_actors
    FROM 
        RecursiveMovie
    GROUP BY 
        production_year
    ORDER BY 
        production_year DESC
)
SELECT 
    yp.production_year,
    yp.total_actors,
    (SELECT COUNT(*) FROM RecursiveMovie WHERE production_year = yp.production_year) AS movie_count
FROM 
    YearlyProduction yp
WHERE 
    yp.total_actors > (
        SELECT AVG(total_actors) FROM YearlyProduction
    )
ORDER BY 
    yp.production_year DESC;
