WITH RankedMovies AS (
    SELECT 
        t.id as movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) as rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    INNER JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
),
MovieKeyword AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ak.actor_name,
    ak.role_name,
    ak.role_count,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ak ON rm.movie_id = ak.movie_id
LEFT JOIN 
    MovieKeyword mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank <= 5 
ORDER BY 
    rm.production_year, rm.title, ak.actor_name;