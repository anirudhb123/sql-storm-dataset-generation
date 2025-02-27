WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        CASE 
            WHEN rm.cast_count IS NULL THEN 'No Cast'
            ELSE 'Has Cast'
        END AS cast_presence
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 0
),
KeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    f.title,
    f.production_year,
    f.cast_count,
    f.cast_presence,
    COALESCE(kc.keyword_count, 0) AS total_keywords,
    CASE 
        WHEN f.cast_count > 10 THEN 'Popular'
        WHEN f.cast_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS popularity_classification
FROM 
    FilteredMovies f
LEFT JOIN 
    KeywordCounts kc ON f.title = (SELECT title FROM aka_title WHERE id = kc.movie_id)
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
