WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN fm.cast_count > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END as cast_presence,
    CASE 
        WHEN keyword_count > 5 THEN 'Rich in Keywords'
        ELSE 'Sparse Keywords'
    END as keyword_richness
FROM 
    FilteredMovies fm
LEFT JOIN 
    KeywordCounts kc ON fm.movie_id = kc.movie_id
WHERE 
    fm.production_year IS NOT NULL
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC NULLS LAST;