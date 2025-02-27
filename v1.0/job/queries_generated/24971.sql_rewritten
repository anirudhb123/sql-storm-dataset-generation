WITH MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        MAX(t.production_year) OVER (PARTITION BY t.id) AS max_production_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    WHERE 
        t.title IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TitleKeyword AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
CompletedCasts AS (
    SELECT 
        cc.movie_id,
        COUNT(*) AS completed_casts
    FROM 
        complete_cast cc
    GROUP BY 
        cc.movie_id
),
EnhancedMovieData AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        tk.keywords,
        cc.completed_casts,
        CASE 
            WHEN cc.completed_casts IS NULL THEN 'Not Completed'
            ELSE 'Completed'
        END AS completion_status
    FROM 
        MovieCTE m
    LEFT JOIN 
        TitleKeyword tk ON m.movie_id = tk.movie_id
    LEFT JOIN 
        CompletedCasts cc ON m.movie_id = cc.movie_id
)
SELECT 
    emd.movie_id,
    emd.title,
    emd.production_year,
    emd.cast_count,
    emd.keywords,
    emd.completion_status,
    CASE 
        WHEN emd.cast_count > 0 THEN emd.cast_count * 1.5
        ELSE 0
    END AS weighted_cast_count,
    CASE 
        WHEN emd.production_year < 2000 THEN 'Classic'
        WHEN emd.production_year BETWEEN 2000 AND 2010 THEN 'Modern Classic'
        ELSE 'Recent'
    END AS era_category
FROM 
    EnhancedMovieData emd
WHERE 
    emd.completion_status = 'Completed'
ORDER BY 
    emd.production_year DESC NULLS LAST,
    emd.cast_count DESC;