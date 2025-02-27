WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank,
        COUNT(DISTINCT ci.person_role_id) OVER (PARTITION BY at.id) AS unique_roles
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
),
AggregatedData AS (
    SELECT 
        production_year,
        COUNT(DISTINCT movie_title) AS total_movies,
        COUNT(DISTINCT actor_name) AS total_actors,
        AVG(unique_roles) AS average_roles_per_movie
    FROM 
        RankedMovies
    GROUP BY 
        production_year
)
SELECT 
    production_year,
    total_movies,
    total_actors,
    average_roles_per_movie,
    CASE 
        WHEN total_movies > 50 THEN 'High Production'
        WHEN total_movies BETWEEN 20 AND 50 THEN 'Medium Production'
        ELSE 'Low Production'
    END AS production_category
FROM 
    AggregatedData
ORDER BY 
    production_year DESC;
