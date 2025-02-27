WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id, c.movie_id, r.role
),
MovieCastStats AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT a.id) AS distinct_actors,
        COUNT(*) AS total_roles,
        SUM(CASE WHEN ar.role_name IS NOT NULL THEN ar.role_count ELSE 0 END) AS total_distinct_roles
    FROM 
        RankedMovies m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        ActorRoles ar ON c.movie_id = ar.movie_id AND c.person_id = ar.person_id
    GROUP BY 
        m.movie_id
)
SELECT 
    m.title,
    m.production_year,
    mcs.distinct_actors,
    mcs.total_roles,
    mcs.total_distinct_roles,
    COALESCE(a.name, 'Unknown') AS actor_name,
    COALESCE(STRING_AGG(DISTINCT ar.role_name, ', '), 'No roles') AS roles_played
FROM 
    MovieCastStats mcs
JOIN 
    RankedMovies m ON mcs.movie_id = m.movie_id
LEFT JOIN 
    cast_info c ON mcs.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    ActorRoles ar ON c.movie_id = ar.movie_id AND c.person_id = ar.person_id
WHERE 
    mcs.distinct_actors > 1 
    AND m.production_year >= 2000 
GROUP BY 
    m.title, m.production_year, mcs.distinct_actors, mcs.total_roles, mcs.total_distinct_roles, a.name
ORDER BY 
    m.production_year DESC, m.title;
