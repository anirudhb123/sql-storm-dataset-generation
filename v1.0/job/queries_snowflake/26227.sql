WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
ActorsInfo AS (
    SELECT 
        p.id AS actor_id,
        p.name AS actor_name,
        c.movie_id,
        r.role AS role_type,
        COUNT(DISTINCT c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        p.id, p.name, c.movie_id, r.role
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(m.id) AS company_count
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id, c.name, ct.kind
)
SELECT 
    rt.movie_title,
    rt.production_year,
    rt.movie_keyword,
    ai.actor_name,
    ai.role_type,
    mc.company_name,
    mc.company_type,
    mc.company_count
FROM 
    RankedTitles rt
JOIN 
    ActorsInfo ai ON rt.production_year = ai.movie_id
JOIN 
    MovieCompanies mc ON mc.movie_id = rt.production_year
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC, ai.role_count DESC, mc.company_count DESC;
