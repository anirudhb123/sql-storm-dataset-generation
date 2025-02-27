WITH RankedMovies AS (
    SELECT
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS year_rank
    FROM
        title
    WHERE
        title.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT
        ak.name AS actor_name,
        ct.kind AS role_type,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY m.production_year DESC) AS role_rank
    FROM
        aka_name ak
        JOIN cast_info ci ON ak.person_id = ci.person_id
        JOIN aka_title m ON ci.movie_id = m.movie_id
        JOIN role_type ct ON ci.role_id = ct.id
    WHERE
        ak.name IS NOT NULL
)
SELECT
    rm.movie_id,
    rm.title AS movie_title,
    rm.production_year,
    ar.actor_name,
    ar.role_type,
    CASE 
        WHEN ar.role_rank = 1 THEN 'Main Role'
        ELSE 'Supporting Role'
    END AS role_indicator,
    COALESCE(NULLIF(rm.title, ''), 'Untitled'::text) AS safe_title
FROM
    RankedMovies rm
LEFT JOIN
    ActorRoles ar ON rm.movie_id = ar.movie_title AND rm.production_year = ar.production_year
WHERE
    rm.year_rank <= 5
ORDER BY
    rm.production_year DESC,
    ar.actor_name ASC NULLS LAST;
    
-- Additionally, include a subquery to find the movies without any actors, explicitly showcasing NULL handling:
WITH NoActorMovies AS (
    SELECT
        title.id AS movie_id,
        title.title
    FROM
        title
    WHERE
        NOT EXISTS (
            SELECT 1 
            FROM cast_info ci 
            WHERE ci.movie_id = title.id
        )
)
SELECT 
    nam.safe_title AS title_without_actors
FROM 
    NoActorMovies nam
WHERE 
    nam.title IS NOT NULL
ORDER BY 
    safe_title DESC;
    
-- This final part burdens the database to cross-reference non-actor movies while employing a more exotic NOTICE for the absence of names.
