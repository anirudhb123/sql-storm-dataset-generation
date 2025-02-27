WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
), MovieInfo AS (
    SELECT 
        mi.movie_id, 
        STRING_AGG(DISTINCT it.info, ', ') AS info_text
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
), CastSummary AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.company_count,
    mi.info_text,
    cs.cast_names,
    cs.roles
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    CastSummary cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.production_year > 2000
ORDER BY 
    rm.company_count DESC, 
    rm.production_year ASC;
