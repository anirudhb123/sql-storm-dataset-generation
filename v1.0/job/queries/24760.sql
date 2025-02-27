
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank_by_title,
        COUNT(*) OVER (PARTITION BY mt.production_year) AS total_movies_per_year
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
AuthoritativeNames AS (
    SELECT 
        ak.name,
        ak.person_id,
        COALESCE(NULLIF(LENGTH(ak.name), 0), 0) AS name_length,
        COUNT(ak.name) OVER (PARTITION BY ak.person_id) as name_count
    FROM 
        aka_name ak
    WHERE 
        ak.name IS NOT NULL
),
FilteredCast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        rt.role,
        COALESCE(NULLIF(rt.role, ''), 'Unknown Role') AS safe_role
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.note IS NULL OR ci.note != 'Cameo'
),
AggregatedNameRoles AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(f.safe_role) AS role_count,
        MAX(f.safe_role) AS most_common_role
    FROM 
        AuthoritativeNames a
    LEFT JOIN 
        FilteredCast f ON a.person_id = f.person_id
    GROUP BY 
        a.person_id, a.name
),
MoviesWithRoles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.role_count,
        ar.most_common_role
    FROM 
        RankedMovies rm
    LEFT JOIN 
        AggregatedNameRoles ar ON rm.movie_id = ar.person_id
)
SELECT 
    mw.title,
    mw.production_year,
    COALESCE(mw.role_count, 0) AS role_count,
    COALESCE(mw.most_common_role, 'No Roles') AS most_common_role,
    (SELECT STRING_AGG(DISTINCT cn.name, ', ') 
     FROM name cn 
     WHERE cn.imdb_id IN (SELECT DISTINCT person_id FROM FilteredCast WHERE movie_id = mw.movie_id)
     ) AS cast_names,
    CASE 
        WHEN mw.role_count IS NULL THEN 'No roles found'
        WHEN mw.role_count > 0 AND mw.role_count < 5 THEN 'Minor Roles'
        WHEN mw.role_count >= 5 AND mw.role_count < 10 THEN 'Supporting Roles'
        ELSE 'Lead Roles'
    END AS role_bracket
FROM 
    MoviesWithRoles mw
WHERE 
    mw.production_year >= 2000
ORDER BY 
    mw.production_year DESC, mw.title ASC
LIMIT 100 OFFSET 0;
