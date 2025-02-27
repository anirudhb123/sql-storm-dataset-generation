
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS total_actors,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actor_names
    FROM 
        title
    LEFT JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.id, title.title, title.production_year
),
RankedByActors AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        total_actors,
        actor_names,
        RANK() OVER (ORDER BY total_actors DESC) AS actor_rank
    FROM 
        RankedMovies
),
GenreInfo AS (
    SELECT 
        title.id AS movie_id,
        STRING_AGG(DISTINCT kind_type.kind, ', ') AS genres
    FROM 
        title
    JOIN 
        kind_type ON title.kind_id = kind_type.id
    GROUP BY 
        title.id
)
SELECT 
    r.movie_id,
    r.movie_title,
    r.production_year,
    r.total_actors,
    r.actor_names,
    g.genres,
    r.actor_rank
FROM 
    RankedByActors r
LEFT JOIN 
    GenreInfo g ON r.movie_id = g.movie_id
WHERE 
    r.total_actors > 2
ORDER BY 
    r.actor_rank, r.production_year DESC
LIMIT 10;
