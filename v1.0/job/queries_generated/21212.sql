WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorParticipation AS (
    SELECT 
        c.movie_id,
        a.id AS actor_id,
        a.name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.id, a.name
),
MoviesWithLeadingActors AS (
    SELECT 
        rm.movie_id, 
        rm.title,
        rm.production_year,
        ap.name AS leading_actor_name,
        ap.role_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorParticipation ap ON rm.movie_id = ap.movie_id
    WHERE 
        ap.role_count = (
            SELECT MAX(role_count)
            FROM ActorParticipation
            WHERE movie_id = rm.movie_id
        )
),
CriticallyAcclaimed AS (
    SELECT 
        mwla.movie_id, 
        mwla.title, 
        mwla.production_year, 
        COALESCE(mi.info, 'No Information') AS critical_info
    FROM 
        MoviesWithLeadingActors mwla
    LEFT JOIN 
        movie_info mi ON mwla.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Critical Rating')
)
SELECT 
    cca.actor_id,
    cca.name AS actor_name,
    cca.role_count,
    cca.movie_id,
    cca.title,
    cca.production_year,
    cca.critical_info
FROM 
    ActorParticipation cca
JOIN 
    CriticallyAcclaimed c ON cca.movie_id = c.movie_id
WHERE 
    cca.role_count > 1
ORDER BY 
    cca.role_count DESC, 
    cca.name ASC
LIMIT 
    10;

-- Notes:
-- This query performs multiple operations:
-- 1. It ranks movies by their title within each production year.
-- 2. Then, it gathers data about actors and the number of roles they played in each movie.
-- 3. It identifies leading actors per movie based on role count.
-- 4. It fetches critical information for movies having leading actors.
-- 5. Finally, it retrieves actors with multiple roles in movies and their critical reception.
