WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS roles_with_notes
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
ActorNames AS (
    SELECT 
        an.id AS actor_id,
        an.name
    FROM 
        aka_name an
),
MoviesWithRoles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        arc.movie_count,
        arc.roles_with_notes,
        ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY arc.movie_count DESC) AS movie_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoleCounts arc ON arc.movie_count > 2
)
SELECT 
    mw.title,
    mw.production_year,
    an.name AS actor_name,
    mw.movie_count,
    mw.roles_with_notes,
    COALESCE(mw.movie_rank, 0) AS movie_rank,
    CASE 
        WHEN mw.roles_with_notes > 0 THEN 'Has Roles'
        ELSE 'No Roles'
    END AS role_status
FROM 
    MoviesWithRoles mw
LEFT JOIN 
    ActorNames an ON an.person_id IN (SELECT person_id FROM cast_info ci WHERE ci.movie_id = mw.movie_id)
WHERE 
    mw.movie_rank <= 5
ORDER BY 
    mw.production_year DESC, 
    mw.movie_count DESC;
