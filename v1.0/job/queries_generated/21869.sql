WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        row_number() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
MoviesWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.role,
        ar.role_count,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY rm.movie_id) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.role, 'Unknown Role') AS role,
    m.role_count,
    m.actor_count,
    CASE 
        WHEN m.production_year IS NULL THEN 'Year: Unknown'
        ELSE FORMAT('Year: %s', m.production_year)
    END AS production_year_display,
    STUFF((
        SELECT 
            STRING_AGG(DISTINCT n.name, ', ') 
        FROM 
            name n 
        JOIN 
            cast_info ci2 ON n.id = ci2.person_id 
        WHERE 
            ci2.movie_id = m.movie_id
        FOR XML PATH('')), 1, 0, '') AS actor_names
FROM 
    MoviesWithActors m
WHERE 
    (m.role_count > 0 OR m.actor_count > 0)
    AND m.production_year IS NOT NULL
ORDER BY 
    m.production_year DESC, m.title;
