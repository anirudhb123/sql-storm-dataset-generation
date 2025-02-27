WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_ranking
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorParticipation AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(*) FILTER (WHERE ci.person_role_id IS NOT NULL) AS role_count,
        COUNT(DISTINCT ci.nr_order) AS distinct_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') FILTER (WHERE cn.country_code IS NOT NULL) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS infos
    FROM 
        movie_info mi 
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    ap.actor_name,
    ap.role_count,
    ap.distinct_roles,
    cd.company_count,
    cd.company_names,
    mi.infos,
    CASE 
        WHEN ap.role_count = 0 THEN 'No Roles'
        WHEN cd.company_count IS NULL THEN 'Company Information Missing'
        ELSE 'All Data Present'
    END AS data_status
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorParticipation ap ON rt.title_id = ap.movie_id 
LEFT JOIN 
    CompanyDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rt.title_id = mi.movie_id
WHERE 
    rt.title_ranking <= 10
ORDER BY 
    rt.production_year ASC, rt.title ASC NULLS LAST;
