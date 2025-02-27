WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank,
        COALESCE(SUM(mk.id), 0) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorMovies AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank,
    COALESCE(am.actor_count, 0) AS actor_count,
    rm.keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorMovies am ON rm.movie_id = am.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2020
    AND rm.rank <= 10
UNION ALL
SELECT 
    NULL AS movie_id,
    'Total Keywords' AS title,
    NULL AS production_year,
    NULL AS rank,
    NULL AS actor_count,
    SUM(keyword_count) AS keyword_count
FROM 
    RankedMovies
HAVING 
    COUNT(*) > 0;
