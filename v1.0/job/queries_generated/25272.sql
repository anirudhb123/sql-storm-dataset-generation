WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
),

CastRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.person_role_id = r.id
    GROUP BY 
        ci.movie_id, ci.person_id, r.role
),

MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS additional_info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info LIKE '%story%'
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    STRING_AGG(DISTINCT cr.role) AS roles,
    STRING_AGG(DISTINCT rm.keyword) AS keywords,
    mi.additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    CastRoles cr ON rm.movie_id = cr.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.keyword_rank <= 3
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, mi.additional_info
ORDER BY 
    rm.production_year DESC, rm.movie_id;
