WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        comp.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name comp ON mc.company_id = comp.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(ac.actor_count, 0) AS number_of_actors,
    STRING_AGG(DISTINCT ci.company_name, ', ') AS production_companies
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorCounts ac ON rt.title_id = ac.movie_id
LEFT JOIN 
    CompanyInfo ci ON rt.title_id = ci.movie_id
WHERE 
    rt.rn <= 5
GROUP BY 
    rt.title, rt.production_year, ac.actor_count
ORDER BY 
    rt.production_year DESC, 
    rt.title;
