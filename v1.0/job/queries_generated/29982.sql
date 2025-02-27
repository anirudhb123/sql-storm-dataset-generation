WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_title t
),
ActorNameCount AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT c.id) AS movie_count,
        STRING_AGG(DISTINCT c.role_id::text, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        aka_name ca ON ca.person_id = c.person_id
    GROUP BY 
        ca.person_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    an.person_id,
    an.movie_count,
    an.roles,
    cd.company_names,
    cd.company_types
FROM 
    RankedTitles rt
JOIN 
    cast_info c ON c.movie_id = rt.title_id
JOIN 
    ActorNameCount an ON an.person_id = c.person_id
LEFT JOIN 
    CompanyDetails cd ON cd.movie_id = rt.title_id
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
