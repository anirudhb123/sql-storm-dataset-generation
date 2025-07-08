
WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        LISTAGG(mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS combined_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT rt.role, ', ') WITHIN GROUP (ORDER BY rt.role) AS roles
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mi.info_count, 0) AS info_count,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    COALESCE(ar.actor_count, 0) AS actor_count,
    COALESCE(ar.roles, 'No roles') AS roles,
    CASE 
        WHEN ar.actor_count > 5 THEN 'Ensemble Cast'
        WHEN ar.actor_count = 0 THEN 'No Actors'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
