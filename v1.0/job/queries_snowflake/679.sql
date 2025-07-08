
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
), ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS unique_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
), MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    WHERE 
        mc.note IS NULL
    GROUP BY 
        mc.movie_id
), MovieInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS movie_info
    FROM 
        movie_info mi 
    WHERE 
        mi.note IS NOT NULL 
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ar.unique_roles, 0) AS total_roles,
    COALESCE(mc.company_count, 0) AS total_companies,
    mi.movie_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 5 OR (mi.movie_info IS NOT NULL AND mc.company_count > 2)
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC
LIMIT 10;
