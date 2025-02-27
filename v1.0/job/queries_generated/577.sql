WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT ca.movie_id) AS movie_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    GROUP BY 
        ca.person_id
),
CompanyMovieStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) FILTER (WHERE co.country_code = 'USA') AS us_company_count,
        COUNT(DISTINCT co.id) AS total_company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    am.actor_names,
    cms.us_company_count,
    cms.total_company_count,
    CASE 
        WHEN cms.us_company_count > 0 THEN 'US Company Involved'
        ELSE 'No US Company'
    END AS company_status,
    COALESCE(am.movie_count, 0) AS actor_movie_count
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorMovies am ON am.movie_count = rt.rank
LEFT JOIN 
    CompanyMovieStats cms ON cms.movie_id = rt.title_id
WHERE 
    rt.rank <= 5 AND 
    (cms.total_company_count IS NULL OR cms.total_company_count > 1)
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
