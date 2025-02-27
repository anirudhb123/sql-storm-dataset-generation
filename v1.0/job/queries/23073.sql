WITH RecursiveActors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.note IS NULL
),
FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),
ActorDetails AS (
    SELECT 
        r.movie_id,
        ARRAY_AGG(DISTINCT r.actor_name) AS actors_list,
        MAX(r.actor_order) AS max_actor_order
    FROM 
        RecursiveActors r
    JOIN 
        FilteredMovies f ON r.movie_id = f.movie_id
    GROUP BY 
        r.movie_id
),
FinalResults AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year,
        a.actors_list,
        a.max_actor_order,
        CASE 
            WHEN f.production_year < 2000 THEN 'Classic'
            WHEN f.production_year BETWEEN 2000 AND 2015 THEN 'Modern'
            ELSE 'Recent'
        END AS era,
        CASE 
            WHEN a.max_actor_order IS NULL THEN 'No Actors'
            ELSE 'Has Actors'
        END AS actor_status
    FROM 
        FilteredMovies f
    LEFT JOIN 
        ActorDetails a ON f.movie_id = a.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    actors_list,
    era,
    actor_status
FROM 
    FinalResults
WHERE 
    actor_status = 'Has Actors'
ORDER BY 
    production_year DESC, 
    title;
