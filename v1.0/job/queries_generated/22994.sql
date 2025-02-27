WITH RECURSIVE MovieCTE AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        COALESCE(mt.production_year, 0) AS production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.id
    GROUP BY 
        mt.id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT
        m.id AS movie_id,
        COALESCE(m.production_year, 0) AS production_year,
        CASE 
            WHEN m.production_year IS NULL THEN 'Unknown Year' 
            ELSE CAST(m.production_year AS text) 
        END AS year_display,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        COALESCE(mc.cast_count, 0) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY COALESCE(kc.keyword_count, 0) DESC, mc.production_year DESC) AS movie_rank
    FROM 
        aka_title m
    LEFT JOIN 
        KeywordCounts kc ON m.id = kc.movie_id
    LEFT JOIN 
        MovieCTE mc ON m.id = mc.movie_id
),
FinalResult AS (
    SELECT 
        mi.movie_id,
        mi.title,
        mi.year_display,
        mi.keyword_count,
        mi.cast_count,
        mi.movie_rank,
        CASE 
            WHEN mi.cast_count = 0 THEN 'No Cast'
            WHEN mi.cast_count < 5 THEN 'Limited Cast'
            ELSE 'Rich Cast'
        END AS cast_quality
    FROM 
        MovieInfo mi
    WHERE 
        mi.year_display != 'Unknown Year'
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.year_display,
    fr.keyword_count,
    fr.cast_count,
    fr.movie_rank,
    fr.cast_quality
FROM 
    FinalResult fr
WHERE 
    fr.movie_rank <= 10
ORDER BY 
    fr.keyword_count DESC,
    fr.cast_quality,
    fr.year_display DESC
LIMIT 15;
