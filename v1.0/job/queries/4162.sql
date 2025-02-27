
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        c.movie_id,
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.role_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.id, a.name
),
MoviesWithCasting AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        ad.actor_name,
        ad.role_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorDetails ad ON rm.movie_id = ad.movie_id
)
SELECT 
    mwc.title,
    mwc.production_year,
    COALESCE(mwc.actor_name, 'No actor listed') AS actor_name,
    CASE 
        WHEN mwc.role_count IS NULL THEN 'Unspecified roles'
        ELSE CONCAT(mwc.role_count, ' roles played')
    END AS role_summary
FROM 
    MoviesWithCasting mwc
WHERE 
    mwc.production_year >= 2000
ORDER BY 
    mwc.production_year DESC, mwc.title;
