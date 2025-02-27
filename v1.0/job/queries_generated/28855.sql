WITH MovieDetails AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        aka_name.name AS actor_name,
        company_name.name AS production_company,
        production_year,
        role_type.role AS role_in_movie
    FROM 
        title
    JOIN 
        movie_info ON title.id = movie_info.movie_id 
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    JOIN 
        cast_info ON aka_title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        role_type ON cast_info.role_id = role_type.id
    WHERE 
        title.production_year >= 2000
        AND company_name.country_code = 'USA'
),

ActorStats AS (
    SELECT 
        actor_name,
        COUNT(movie_id) AS movie_count,
        STRING_AGG(movie_title, ', ') AS movies
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
    ORDER BY 
        movie_count DESC
    LIMIT 10
)

SELECT 
    actor_name,
    movie_count,
    movies,
    CASE 
        WHEN movie_count > 5 THEN 'Prolific Actor'
        WHEN movie_count BETWEEN 2 AND 5 THEN 'Emerging Talent'
        ELSE 'Novice Actor'
    END AS actor_status
FROM 
    ActorStats;
