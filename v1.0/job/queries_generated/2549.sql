WITH RankedTitles AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.id AS actor_id,
        ak.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.id, ak.name
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT c.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ad.name AS actor_name,
    ad.movie_count,
    cd.companies
FROM 
    RankedTitles rt
LEFT JOIN 
    cast_info ci ON rt.id = ci.movie_id
LEFT JOIN 
    ActorDetails ad ON ci.person_id = ad.person_id
LEFT JOIN 
    CompanyDetails cd ON rt.id = cd.movie_id
WHERE 
    rt.production_year BETWEEN 2000 AND 2023
AND 
    ad.movie_count > 5
ORDER BY 
    rt.production_year DESC, rt.title;
