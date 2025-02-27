WITH actor_movies AS (
    SELECT 
        ca.person_id,
        a.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        kt.keyword AS movie_keyword
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        aka_title at ON ca.movie_id = at.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = ca.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    WHERE 
        a.name IS NOT NULL -- Only considering actors with valid names
),
movie_stats AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS total_movies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS unique_keywords,
        MIN(production_year) AS first_movie_year,
        MAX(production_year) AS latest_movie_year
    FROM 
        actor_movies
    GROUP BY 
        actor_name
),
actors_above_threshold AS (
    SELECT 
        actor_name,
        total_movies,
        unique_keywords,
        first_movie_year,
        latest_movie_year
    FROM 
        movie_stats
    WHERE 
        total_movies > 10 -- Filter actors with more than 10 movies
)
SELECT 
    actor_name,
    total_movies,
    unique_keywords,
    first_movie_year,
    latest_movie_year,
    latest_movie_year - first_movie_year AS movie_span
FROM 
    actors_above_threshold
ORDER BY 
    total_movies DESC, actor_name;
