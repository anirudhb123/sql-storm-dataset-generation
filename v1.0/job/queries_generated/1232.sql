WITH RecursiveTitles AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        t.season_nr,
        t.episode_nr,
        t.episode_of_id,
        ROW_NUMBER() OVER (PARTITION BY t.episode_of_id ORDER BY t.season_nr, t.episode_nr) AS episode_order
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
MovieInfoCTE AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
CompanyMovieCTE AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
ActorTitleCTE AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.id) AS num_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
)
SELECT 
    rt.title,
    rt.production_year,
    rt.episode_order,
    COALESCE(cte.info_details, 'No Info') AS movie_info,
    COALESCE(cmc.company_name, 'Independent') AS production_company,
    COALESCE(cmc.company_type, 'N/A') AS company_type,
    ak.actor_name,
    ak.num_roles
FROM 
    RecursiveTitles rt
LEFT JOIN 
    MovieInfoCTE cte ON rt.id = cte.movie_id
LEFT JOIN 
    CompanyMovieCTE cmc ON rt.id = cmc.movie_id
LEFT JOIN 
    ActorTitleCTE ak ON rt.id = ak.movie_id
WHERE 
    (rt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series')))
    AND (rt.episode_of_id IS NULL OR rt.episode_of_id NOT IN (SELECT id FROM title WHERE kind_id = (SELECT id FROM kind_type WHERE kind = 'series')))
ORDER BY 
    rt.production_year DESC, rt.episode_order;
