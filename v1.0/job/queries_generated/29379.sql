WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER(ORDER BY a.production_year DESC, COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON mc.movie_id = a.id
    JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = a.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = a.id
    GROUP BY 
        a.id, a.title, a.production_year, c.name
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        keywords,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    movie_title,
    production_year,
    company_name,
    keywords,
    actor_count
FROM 
    TopMovies
ORDER BY 
    production_year DESC, actor_count DESC;

This SQL query evaluates the top 10 movies based on their production year and the number of distinct actors involved in the film. It combines data from multiple tables to get movie titles, production years, companies associated with the movies, keywords associated with the movies, and actor counts. The results are ordered by production year and the number of actors to showcase the most recent and popular films based on actor participation.
