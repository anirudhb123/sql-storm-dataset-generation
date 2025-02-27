WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorPerformance AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(mi.info_length) AS avg_info_length
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_info mi ON ci.movie_id = mi.movie_id
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        a.name
),
MovieKeywords AS (
    SELECT 
        kt.keyword,
        mk.movie_id
    FROM 
        keyword kt
    JOIN 
        movie_keyword mk ON kt.id = mk.keyword_id
)
SELECT 
    rm.title,
    rm.production_year,
    ap.actor_name,
    ap.movie_count,
    ap.avg_info_length,
    COUNT(mk.movie_id) AS keyword_count,
    COALESCE(AP.movie_count * mk.keyword_count, 0) AS performance_score
FROM 
    RankedMovies rm
JOIN 
    ActorPerformance ap ON rm.title_rank = ap.movie_count
LEFT JOIN 
    MovieKeywords mk ON rm.title = mk.keyword
WHERE 
    (rm.production_year >= 2000 AND rm.production_year <= 2023)
    OR (ap.avg_info_length IS NULL)
GROUP BY 
    rm.title, rm.production_year, ap.actor_name, ap.movie_count, ap.avg_info_length
HAVING 
    COUNT(mk.movie_id) > 1
ORDER BY 
    performance_score DESC, rm.production_year DESC;
