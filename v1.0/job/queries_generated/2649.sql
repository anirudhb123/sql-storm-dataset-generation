WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    INNER JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
        AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', rt.role, ')'), ', ') AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ar.actor_count, 0) AS actor_count,
    ar.actors,
    COALESCE(mk.keyword_count, 0) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    (ar.actor_count > 5 OR mk.keyword_count > 2)
ORDER BY 
    rm.production_year DESC,
    rm.title ASC
LIMIT 100;
