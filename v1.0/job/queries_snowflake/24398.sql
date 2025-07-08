WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CoActors AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS co_actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
FullMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ca.co_actor_count, 0) AS co_actor_count,
        CASE 
            WHEN ca.co_actor_count IS NULL THEN 'No Co-Headers'
            WHEN ca.co_actor_count > 3 THEN 'Popular Cast'
            ELSE 'Moderate Cast'
        END AS cast_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CoActors ca ON rm.movie_id = ca.movie_id
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
FinalResults AS (
    SELECT 
        fmi.movie_id,
        fmi.title,
        fmi.production_year,
        fmi.co_actor_count,
        fmi.cast_type,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        fmi.production_year - AVG(fmi.production_year) OVER () AS year_diff
    FROM 
        FullMovieInfo fmi
    LEFT JOIN 
        KeywordCounts kc ON fmi.movie_id = kc.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.co_actor_count,
    f.cast_type,
    f.keyword_count,
    CASE 
        WHEN f.year_diff < 0 THEN 'Before Average Year'
        WHEN f.year_diff > 0 THEN 'After Average Year'
        ELSE 'Average Year'
    END AS year_comparison
FROM 
    FinalResults f
WHERE 
    (f.co_actor_count >= 5 OR f.keyword_count >= 10)
    AND (f.production_year IS NOT NULL OR f.title IS NOT NULL)
ORDER BY 
    f.production_year DESC,
    f.keyword_count DESC,
    f.co_actor_count ASC;
