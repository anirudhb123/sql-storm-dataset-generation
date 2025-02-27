WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        MAX(r.role) AS lead_role
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
TopMovies AS (
    SELECT 
        rm.title,
        COALESCE(ar.actor_count, 0) AS actor_count,
        rm.keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.id = ar.movie_id 
    WHERE 
        rm.rn = 1
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    COALESCE(tm.keyword, 'No Keywords') AS keyword
FROM 
    TopMovies tm
WHERE 
    tm.actor_count > 5
ORDER BY 
    tm.production_year DESC
LIMIT 10;
