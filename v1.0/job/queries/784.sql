WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.actor_count,
        m.actor_names,
        COALESCE(mu.info, 'No additional info') AS additional_info
    FROM 
        ActorRoles m
    LEFT JOIN 
        movie_info mu ON m.movie_id = mu.movie_id AND mu.info_type_id = 1 
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    md.actor_count,
    md.actor_names,
    md.additional_info
FROM 
    RankedMovies r
JOIN 
    MovieDetails md ON r.movie_id = md.movie_id
WHERE 
    r.rn <= 5 
ORDER BY 
    r.production_year DESC, 
    r.title ASC;