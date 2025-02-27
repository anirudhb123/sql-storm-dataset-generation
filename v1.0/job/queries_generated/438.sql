WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_in_year
    FROM 
        aka_title a 
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_in_year <= 5
),
ActorRoles AS (
    SELECT 
        p.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_played,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        ci.note IS NULL
    GROUP BY 
        p.name
)
SELECT 
    fm.title,
    fm.production_year,
    ar.actor_name,
    ar.movies_played,
    ar.titles
FROM 
    FilteredMovies fm
JOIN 
    ActorRoles ar ON ar.titles LIKE '%' || fm.title || '%'
ORDER BY 
    fm.production_year, fm.actor_count DESC
LIMIT 10;
