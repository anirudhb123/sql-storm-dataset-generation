WITH RecursiveActorLifespans AS (
    SELECT 
        c.person_id,
        MIN(t.production_year) AS first_movie_year,
        MAX(t.production_year) AS last_movie_year,
        COUNT(DISTINCT t.id) AS movie_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        aka_title t ON t.id = c.movie_id
    GROUP BY 
        c.person_id
),
DoubleMovieActors AS (
    SELECT 
        person_id, 
        movie_count,
        actor_names
    FROM 
        RecursiveActorLifespans 
    WHERE 
        movie_count >= 2
),
TopActorsAsOfYear AS (
    SELECT 
        person_id,
        actor_names,
        first_movie_year,
        last_movie_year,
        RANK() OVER (ORDER BY movie_count DESC) AS rank,
        COUNT(DISTINCT t.id) FILTER (WHERE t.production_year = 2023) AS movies_in_2023
    FROM 
        DoubleMovieActors da
    JOIN 
        cast_info c ON c.person_id = da.person_id
    JOIN 
        aka_title t ON t.id = c.movie_id
    GROUP BY 
        person_id, actor_names, first_movie_year, last_movie_year
)

SELECT 
    a.actor_names,
    a.first_movie_year,
    a.last_movie_year,
    a.movie_count,
    COALESCE(b.movies_in_2023, 0) AS movies_in_2023,
    CASE 
        WHEN a.movie_count >= 5 AND COALESCE(b.movies_in_2023, 0) > 0 THEN 'Active and Prolific'
        WHEN a.movie_count >= 5 THEN 'Prolific but Inactive'
        WHEN COALESCE(b.movies_in_2023, 0) > 0 THEN 'Active but Less Prolific'
        ELSE 'Rarely Active'
    END AS activity_status
FROM 
    DoubleMovieActors a
LEFT JOIN 
    TopActorsAsOfYear b ON a.person_id = b.person_id
ORDER BY 
    a.movie_count DESC, 
    b.movies_in_2023 DESC NULLS LAST;

