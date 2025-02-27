WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND k.phonetic_code IS NOT NULL
), MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', rt.role, ')'), ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        c.movie_id
), MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT CONCAT(mi.info_type_id, ': ', mi.info), '; ') AS movie_info
    FROM 
        movie_info m
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    mc.cast_count,
    mc.cast_names,
    mi.movie_info,
    STRING_AGG(DISTINCT rm.keyword, ', ') AS keywords
FROM
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, mc.cast_count, mc.cast_names, mi.movie_info
ORDER BY 
    rm.production_year DESC, rm.movie_id;
