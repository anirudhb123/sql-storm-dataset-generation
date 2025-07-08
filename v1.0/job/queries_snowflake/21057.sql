
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank_in_year
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
CastCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cc.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastCount cc ON rm.movie_id = cc.movie_id
    WHERE 
        rm.rank_in_year <= 5 AND
        cc.actor_count > 2
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        COALESCE(kc.keywords, 'No Keywords') AS keywords,
        kc.keyword_total
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        KeywordCounts kc ON fm.movie_id = kc.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.keywords,
    fr.keyword_total,
    CASE 
        WHEN fr.keyword_total IS NULL THEN 'No Keywords Found'
        WHEN fr.keyword_total > 5 THEN 'Keyword Rich'
        ELSE 'Keyword Poor'
    END AS keyword_quality,
    CASE 
        WHEN fr.production_year IS NOT NULL THEN 2023 - fr.production_year
        ELSE NULL 
    END AS years_since_release
FROM 
    FinalResults fr
WHERE 
    fr.production_year IS NOT NULL
ORDER BY 
    fr.production_year DESC, 
    fr.keyword_total DESC NULLS LAST;
