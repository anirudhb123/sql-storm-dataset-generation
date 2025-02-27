WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
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
CompanyInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies m
    JOIN company_name cn ON m.company_id = cn.id
    JOIN company_type ct ON m.company_type_id = ct.id
    GROUP BY m.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ac.actor_count,
    ci.companies,
    ci.company_types,
    CASE 
        WHEN ac.actor_count > 5 THEN 'Many Actors'
        WHEN ac.actor_count IS NULL THEN 'No Actors'
        ELSE 'Few Actors'
    END AS actor_description,
    COALESCE(NULLIF(rt.rank, 0), 'Unranked') AS title_rank
FROM RankedTitles rt
LEFT JOIN ActorCounts ac ON rt.title_id = ac.movie_id
LEFT JOIN CompanyInfo ci ON rt.title_id = ci.movie_id
WHERE rt.rank <= 10
ORDER BY rt.production_year DESC, rt.title;
