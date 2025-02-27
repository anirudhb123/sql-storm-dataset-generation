WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
ActorMovieCounts AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT production_year) AS unique_years_active,
        COUNT(*) AS total_movies
    FROM 
        RankedTitles
    GROUP BY 
        actor_name
),
TopActors AS (
    SELECT 
        actor_name,
        total_movies,
        unique_years_active,
        RANK() OVER (ORDER BY total_movies DESC) AS rank
    FROM 
        ActorMovieCounts
    WHERE 
        unique_years_active > 5
)
SELECT 
    a.actor_name,
    a.total_movies,
    a.unique_years_active,
    STRING_AGG(DISTINCT t.title, ', ') AS titles
FROM 
    TopActors a
JOIN 
    RankedTitles t ON a.actor_name = t.actor_name
WHERE 
    a.rank <= 10
GROUP BY 
    a.actor_name, a.total_movies, a.unique_years_active
ORDER BY 
    a.total_movies DESC;
