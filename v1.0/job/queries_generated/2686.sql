WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_by_year
    FROM title t
    WHERE t.production_year >= 2000
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.movie_id
),
MovieInsights AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        CASE 
            WHEN r.rank_by_year <= 5 THEN 'Top 5' 
            ELSE 'Others' 
        END AS rank_category
    FROM RankedMovies r
    LEFT JOIN ActorCounts ac ON r.movie_id = ac.movie_id
)
SELECT 
    mi.title,
    mi.production_year,
    mi.actor_count,
    CASE 
        WHEN mi.actor_count > 10 THEN 'Large Ensemble' 
        WHEN mi.actor_count BETWEEN 5 AND 10 THEN 'Medium Ensemble' 
        ELSE 'Small Cast' 
    END AS cast_size,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM MovieInsights mi
LEFT JOIN movie_keyword mk ON mi.movie_id = mk.movie_id
GROUP BY mi.movie_id, mi.title, mi.production_year, mi.actor_count
HAVING COUNT(DISTINCT mk.keyword) > 2
ORDER BY mi.production_year DESC, mi.actor_count DESC;
