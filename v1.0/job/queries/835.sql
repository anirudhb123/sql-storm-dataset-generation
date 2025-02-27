WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    INNER JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, a.name, rt.role
),
MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        COALESCE(ar.actor_name, 'Unknown Actor') AS actor_name,
        COALESCE(ar.role_name, 'Unknown Role') AS role_name,
        COALESCE(ar.role_count, 0) AS role_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.title_id = ar.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    md.role_name,
    CASE 
        WHEN md.role_count IS NULL THEN 'No roles'
        ELSE CAST(md.role_count AS text)
    END AS role_count,
    SUBSTRING(md.actor_name FROM 1 FOR 5) || '...' AS abbreviated_actor_name,
    CONCAT('Title: ', md.title, ', Year: ', md.production_year) AS title_info
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.actor_name;
