WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count,
        cd.companies,
        cd.company_count,
        CASE 
            WHEN ac.actor_count > 5 THEN 'Blockbuster'
            WHEN ac.actor_count BETWEEN 3 AND 5 THEN 'Popular'
            ELSE 'Indie'
        END AS movie_category
    FROM RankedMovies rm
    LEFT JOIN ActorCounts ac ON rm.movie_id = ac.movie_id
    LEFT JOIN CompanyDetails cd ON rm.movie_id = cd.movie_id
)
SELECT 
    cm.movie_id,
    cm.title,
    COALESCE(cm.production_year, 'Unknown Year') AS production_info,
    cm.actor_count,
    COALESCE(cm.companies, 'No companies listed') AS company_list,
    cm.company_count,
    cm.movie_category
FROM CompleteMovieInfo cm
WHERE cm.actor_count IS NOT NULL
ORDER BY cm.production_year DESC, cm.title ASC
LIMIT 50;
