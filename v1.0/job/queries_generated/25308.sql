WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
ActorTitles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        at.title_id,
        at.title,
        at.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RankedTitles at ON ci.movie_id = at.title_id
),
CompanyContribution AS (
    SELECT 
        m.id AS movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(m.id) AS contribution_count
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.id, c.name, ct.kind
)
SELECT 
    at.actor_name,
    STRING_AGG(at.title, ', ') AS titles,
    STRING_AGG(DISTINCT cc.company_name || ' (' || cc.company_type || ')', '; ') AS companies,
    COUNT(DISTINCT at.title_id) AS title_count
FROM 
    ActorTitles at
LEFT JOIN 
    CompanyContribution cc ON at.title_id = cc.movie_id
GROUP BY 
    at.actor_name
ORDER BY 
    title_count DESC;
