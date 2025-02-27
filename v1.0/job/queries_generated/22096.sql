WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
CastRoles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
), 
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(i.info, '; ') AS info_details
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    WHERE 
        m.info IS NOT NULL AND it.info LIKE '%%Director%'
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cr.role, 'Unknown') AS role,
    COALESCE(cr.role_count, 0) AS role_count,
    CASE 
        WHEN mi.info_details IS NOT NULL THEN mi.info_details
        ELSE 'No additional info'
    END AS additional_info,
    COUNT(DISTINCT ca.id) AS actor_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CastRoles cr ON rm.movie_id = cr.movie_id
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name an ON cc.subject_id = an.person_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    cast_info ca ON rm.movie_id = ca.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, cr.role, mi.info_details
HAVING 
    COUNT(DISTINCT ca.id) >= 1
ORDER BY 
    rm.production_year DESC, role_count DESC NULLS LAST;
