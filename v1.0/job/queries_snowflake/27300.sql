
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id, 
        a.title, 
        a.production_year,
        COALESCE(k.keyword, 'No keywords') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
MovieCast AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT p.name, ', ') WITHIN GROUP (ORDER BY p.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT
        mi.movie_id,
        LISTAGG(DISTINCT it.info, '; ') WITHIN GROUP (ORDER BY it.info) AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    mc.cast_count,
    mc.cast_names,
    mi.info_details,
    rm.keyword
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rn = 1
ORDER BY 
    rm.production_year DESC, 
    mc.cast_count DESC;
