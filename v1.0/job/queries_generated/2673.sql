WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM cast_info c
    GROUP BY c.person_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
MoviesWithActors AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ac.person_id,
        COALESCE(ac.movie_count, 0) AS movie_count,
        ci.companies
    FROM RankedTitles rt
    LEFT JOIN cast_info c ON c.movie_id = rt.title_id
    LEFT JOIN ActorMovieCounts ac ON ac.person_id = c.person_id
    LEFT JOIN CompanyInfo ci ON ci.movie_id = rt.title_id
)
SELECT 
    mw.title,
    mw.production_year,
    mw.person_id,
    mw.movie_count,
    CASE 
        WHEN mw.movie_count > 0 THEN 'Active Actor'
        ELSE 'Inactive Actor'
    END AS actor_status,
    mw.companies
FROM MoviesWithActors mw
WHERE mw.production_year = (SELECT MAX(production_year) FROM RankedTitles)
ORDER BY mw.title ASC;
