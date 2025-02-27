WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as rn
    FROM title t
    WHERE t.production_year IS NOT NULL
), 
ActorMovies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
), 
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    COALESCE(am.actor_count, 0) AS actor_count,
    COALESCE(cm.company_count, 0) AS company_count,
    CASE 
        WHEN am.actor_count >= 10 THEN 'High Actor Count'
        WHEN am.actor_count BETWEEN 5 AND 9 THEN 'Medium Actor Count'
        ELSE 'Low Actor Count'
    END AS actor_count_category,
    CASE 
        WHEN cm.company_count > 5 THEN 'Produced by Many'
        ELSE 'Produced by Few'
    END AS company_count_category
FROM RankedMovies rm
LEFT JOIN ActorMovies am ON rm.title_id = am.movie_id
LEFT JOIN CompanyMovies cm ON rm.title_id = cm.movie_id
WHERE rm.rn <= 10
ORDER BY rm.production_year DESC, actor_count DESC;
