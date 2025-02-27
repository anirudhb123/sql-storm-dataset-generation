WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CastInfoSummary AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
MovieCompaniesSummary AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.company_id) AS company_count,
        MAX(cn.name) AS main_company
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    coalesce(css.actor_count, 0) AS total_actors,
    coalesce(css.actor_names, 'No actors found') AS actor_list,
    coalesce(mcs.company_count, 0) AS total_companies,
    coalesce(mcs.main_company, 'No company found') AS leading_company
FROM 
    RankedTitles rt
LEFT JOIN 
    CastInfoSummary css ON rt.title_id = css.movie_id
LEFT JOIN 
    MovieCompaniesSummary mcs ON rt.title_id = mcs.movie_id
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC,
    rt.title;
