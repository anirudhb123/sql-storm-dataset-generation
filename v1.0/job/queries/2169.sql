WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
), MovieActors AS (
    SELECT 
        m.movie_id,
        a.name AS actor_name,
        COUNT(c.id) AS total_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        RankedMovies m ON c.movie_id = m.movie_id
    GROUP BY 
        m.movie_id, a.name
), ActorRankings AS (
    SELECT 
        movie_id,
        actor_name,
        total_roles,
        RANK() OVER (PARTITION BY movie_id ORDER BY total_roles DESC) AS actor_rank
    FROM 
        MovieActors
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(a.actor_name, 'No Actors') AS actor_name,
    COALESCE(a.total_roles, 0) AS total_roles,
    CASE 
        WHEN a.actor_rank <= 3 THEN 'Top Performer'
        ELSE 'Supporting Actor'
    END AS performance_level
FROM 
    RankedMovies r
LEFT JOIN 
    ActorRankings a ON r.movie_id = a.movie_id
WHERE 
    (r.production_year IS NOT NULL AND r.rank <= 5)
ORDER BY 
    r.production_year DESC, r.movie_id, a.actor_rank;
