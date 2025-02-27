WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieGenres AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS genres
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    COALESCE(mg.genres, 'No Genre') AS genre_list
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
WHERE 
    rn <= 10
ORDER BY 
    rm.production_year DESC, total_actors DESC
LIMIT 20;
