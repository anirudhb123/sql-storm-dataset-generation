WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MoviesWithInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(ac.actor_count, 0) AS actor_count,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        mt.production_year,
        CASE 
            WHEN ac.actor_count IS NULL THEN 0
            ELSE 
                ROUND((COALESCE(mkc.keyword_count, 0) * 1.0 / ac.actor_count), 2) 
        END AS keywords_per_actor
    FROM 
        aka_title mt
    LEFT JOIN 
        ActorCounts ac ON mt.id = ac.movie_id
    LEFT JOIN 
        MovieKeywordCounts mkc ON mt.id = mkc.movie_id
)
SELECT 
    mwi.title,
    mwi.production_year,
    mwi.actor_count,
    mwi.keyword_count,
    mwi.keywords_per_actor,
    rk.year_rank
FROM 
    MoviesWithInfo mwi
JOIN 
    RankedMovies rk ON mwi.production_year = rk.production_year
WHERE 
    mwi.actor_count > 0
ORDER BY 
    mwi.production_year DESC, 
    mwi.keywords_per_actor DESC
LIMIT 10;
