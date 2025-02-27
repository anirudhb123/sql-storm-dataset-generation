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
ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        mt.title AS movie_title,
        mt.production_year,
        c.role_id AS role_id,
        r.role AS role_name
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title mt ON c.movie_id = mt.id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyInfo AS (
    SELECT 
        c.id AS company_id,
        c.name AS company_name,
        ct.kind AS company_type,
        mc.movie_id
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    at.actor_name,
    a.movie_title,
    COALESCE(c.company_name, 'Unknown') AS company_name,
    STRING_AGG(DISTINCT c.company_type, ', ') AS company_types,
    rt.title AS ranked_title,
    rt.production_year AS ranked_year
FROM 
    ActorMovies a
LEFT JOIN 
    CompanyInfo c ON a.movie_title = c.movie_id 
LEFT JOIN 
    RankedTitles rt ON a.movie_title = rt.title_id
GROUP BY 
    at.actor_name, a.movie_title, c.company_name, rt.title, rt.production_year
HAVING 
    COUNT(a.movie_title) > 1
ORDER BY 
    a.actor_name, rt.production_year DESC
LIMIT 50;
