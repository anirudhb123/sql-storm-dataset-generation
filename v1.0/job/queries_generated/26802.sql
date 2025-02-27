WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS genre,
        COALESCE(cast_actors.actor_count, 0) AS actor_count,
        COALESCE(companies.company_count, 0) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COALESCE(cast_actors.actor_count, 0) DESC, COALESCE(companies.company_count, 0) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        (SELECT 
            movie_id, 
            COUNT(DISTINCT person_id) AS actor_count
         FROM 
            cast_info
         GROUP BY 
            movie_id) AS cast_actors ON t.id = cast_actors.movie_id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            COUNT(DISTINCT company_id) AS company_count
         FROM 
            movie_companies
         GROUP BY 
            movie_id) AS companies ON t.id = companies.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
)

SELECT 
    production_year,
    COUNT(movie_title) AS total_movies,
    AVG(actor_count) AS avg_actors_per_movie,
    AVG(company_count) AS avg_companies_per_movie,
    STRING_AGG(DISTINCT genre, ', ') AS genres
FROM 
    RankedMovies
GROUP BY 
    production_year
HAVING 
    COUNT(movie_title) > 10
ORDER BY 
    production_year DESC;
