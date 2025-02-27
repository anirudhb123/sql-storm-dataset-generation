WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM t.production_year) ORDER BY t.production_year DESC) AS year_rank,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.movie_id IN (SELECT movie_id FROM TopMovies)
    GROUP BY 
        ci.movie_id, a.name, rt.role
),
ActorMovieSummary AS (
    SELECT 
        t.title,
        t.production_year,
        ar.actor_name,
        ar.role,
        ar.role_count
    FROM 
        TopMovies t
    LEFT JOIN 
        ActorRoles ar ON t.movie_id = ar.movie_id
)
SELECT 
    ams.title,
    ams.production_year,
    COALESCE(ams.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(ams.role, 'No Role Assigned') AS role,
    COALESCE(ams.role_count, 0) AS role_count
FROM 
    ActorMovieSummary ams
ORDER BY 
    ams.production_year DESC, ams.title;
