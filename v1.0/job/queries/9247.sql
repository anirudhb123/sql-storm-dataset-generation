WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_name,
        ar.role
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
)
SELECT 
    md.title,
    md.production_year,
    STRING_AGG(md.actor_name || ' (' || md.role || ')', ', ') AS cast
FROM 
    MovieDetails md
GROUP BY 
    md.movie_id, md.title, md.production_year
ORDER BY 
    md.production_year DESC, md.title;
