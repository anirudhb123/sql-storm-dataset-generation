
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        m.movie_id,
        a.name AS actor_name,
        c.role_id,
        COUNT(c.id) AS num_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        RankedMovies m ON c.movie_id = m.movie_id
    GROUP BY 
        m.movie_id, a.name, c.role_id
),
ActorRanking AS (
    SELECT 
        actor_name,
        SUM(num_roles) AS total_roles,
        ROW_NUMBER() OVER (ORDER BY SUM(num_roles) DESC) AS actor_rank
    FROM 
        MovieCast
    GROUP BY 
        actor_name
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(mc.actor_name, 'Unknown') AS actor_name,
    COALESCE(ar.total_roles, 0) AS actor_roles,
    COALESCE(r.total_movies, 0) AS movies_in_year,
    CASE
        WHEN m.rn = 1 THEN 'First Movie of Year'
        WHEN m.rn = 2 THEN 'Second Movie of Year'
        ELSE 'Subsequent Movie of Year'
    END AS movie_rank_description
FROM 
    RankedMovies m
LEFT JOIN 
    MovieCast mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    ActorRanking ar ON mc.actor_name = ar.actor_name
LEFT JOIN (
    SELECT 
        production_year, COUNT(*) AS total_movies
    FROM 
        aka_title
    GROUP BY 
        production_year
) r ON m.production_year = r.production_year
ORDER BY 
    m.production_year DESC, m.movie_id ASC
FETCH FIRST 100 ROWS ONLY;
