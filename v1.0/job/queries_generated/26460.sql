WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
MovieInfo AS (
    SELECT
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        COALESCE(MAX(CASE WHEN mi.info_type_id = it.id THEN mi.info END), 'N/A') AS info 
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year, rm.cast_count
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    mi.movie_id,
    mi.movie_title,
    mi.production_year,
    mi.cast_count,
    mi.info,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM 
    MovieInfo mi
LEFT JOIN 
    KeywordCount kc ON mi.movie_id = kc.movie_id
ORDER BY 
    mi.production_year DESC, 
    mi.cast_count DESC, 
    mi.movie_title;
