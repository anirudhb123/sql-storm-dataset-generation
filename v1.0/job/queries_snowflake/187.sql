
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
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
CompanyInformation AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT co.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_type_id) AS company_type_count
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
    a.name AS actor_name,
    ac.movie_count,
    ci.companies,
    ci.company_type_count,
    CASE 
        WHEN ci.company_type_count > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_multiple_company_types
FROM 
    RankedTitles rt
LEFT JOIN 
    cast_info c ON rt.title_id = c.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = c.person_id
LEFT JOIN 
    ActorMovieCounts ac ON ac.person_id = c.person_id
LEFT JOIN 
    CompanyInformation ci ON ci.movie_id = rt.title_id
WHERE 
    rt.rn <= 5 
    AND (rt.production_year IS NULL OR rt.production_year > 2000) 
    AND (ci.company_type_count IS NULL OR ci.company_type_count <= 3)
ORDER BY 
    rt.production_year DESC, 
    rt.title;
