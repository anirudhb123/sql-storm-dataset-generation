WITH RankedActors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank,
        c.movie_id
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(*) AS actor_count
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.actor_count,
        RANK() OVER (ORDER BY md.actor_count DESC) AS movie_rank
    FROM 
        MovieDetails md
    WHERE 
        md.production_year >= 2000
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.actor_count,
    ra.actor_name,
    ra.actor_rank
FROM 
    TopMovies tm
JOIN 
    RankedActors ra ON tm.movie_id = ra.movie_id
WHERE 
    tm.movie_rank <= 10
ORDER BY 
    tm.actor_count DESC, 
    ra.actor_rank ASC;