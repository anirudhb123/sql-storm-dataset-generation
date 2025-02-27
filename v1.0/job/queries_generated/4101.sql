WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as year_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) as cast_count
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = a.id
    WHERE 
        a.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5 AND rm.cast_count > 0
),
MovieKeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
FinalResult AS (
    SELECT 
        fm.title,
        fm.production_year,
        fm.cast_count,
        COALESCE(mkc.keyword_count, 0) AS keyword_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        MovieKeywordCounts mkc ON fm.title = mkc.movie_id
)
SELECT 
    title,
    production_year,
    cast_count,
    keyword_count,
    CASE 
        WHEN cast_count > 10 THEN 'Ensemble Cast'
        WHEN cast_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Short Cast'
    END AS cast_type
FROM 
    FinalResult
WHERE 
    (keyword_count > 0 OR cast_count > 0)
ORDER BY 
    production_year DESC, keyword_count DESC;
