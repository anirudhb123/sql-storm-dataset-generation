WITH MovieGenres AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS genres
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        t.id
),
TopActors AS (
    SELECT 
        c.movie_id,
        a.name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY COUNT(c.person_id) DESC) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
),
MoviesWithActorCount AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        complete_cast m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    t.title,
    t.production_year,
    mg.genres,
    COALESCE(mwa.actor_count, 0) AS total_actors,
    ta.name AS top_actor
FROM 
    aka_title t
LEFT JOIN 
    MovieGenres mg ON t.id = mg.movie_id
LEFT JOIN 
    MoviesWithActorCount mwa ON t.id = mwa.movie_id
LEFT JOIN 
    TopActors ta ON t.id = ta.movie_id AND ta.actor_rank = 1
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC,
    total_actors DESC
LIMIT 100;
