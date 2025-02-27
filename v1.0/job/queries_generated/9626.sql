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
MovieCompanies AS (
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
CompleteCastInfo AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    mc.company_name,
    mc.company_type,
    c.actor_count,
    c.roles
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieCompanies mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    CompleteCastInfo c ON rt.title_id = c.movie_id
WHERE 
    rt.rn <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
