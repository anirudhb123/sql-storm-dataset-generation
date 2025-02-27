
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
),
ActorCount AS (
    SELECT 
        movie_id,
        COUNT(actor_name) AS actor_count
    FROM 
        RankedMovies
    GROUP BY 
        movie_id
),
AverageProductionYear AS (
    SELECT 
        AVG(production_year) AS average_year
    FROM 
        aka_title
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    ac.actor_count,
    CASE 
        WHEN m.production_year < avg.average_year THEN 'Older than Average'
        WHEN m.production_year > avg.average_year THEN 'Newer than Average'
        ELSE 'Average Year'
    END AS year_comparison
FROM 
    RankedMovies m
JOIN 
    ActorCount ac ON m.movie_id = ac.movie_id
CROSS JOIN 
    AverageProductionYear avg
WHERE 
    ac.actor_count > 5
ORDER BY 
    m.production_year DESC, 
    ac.actor_count DESC;
