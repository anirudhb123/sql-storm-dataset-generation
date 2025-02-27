WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT c.name) AS cast_names
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(ci.person_id) > 5
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
DetailedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        kc.keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordCount kc ON rm.movie_id = kc.movie_id
)
SELECT 
    dm.movie_id,
    dm.title,
    dm.production_year,
    dm.cast_count,
    dm.cast_names,
    COALESCE(dm.keyword_count, 0) AS keyword_count
FROM 
    DetailedMovies dm
ORDER BY 
    dm.production_year DESC, 
    dm.cast_count DESC;
