WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS title_rank
    FROM 
        aka_title a
),
ActorTitles AS (
    SELECT 
        c.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS actor_title_rank
    FROM 
        cast_info c
    JOIN 
        aka_title t ON c.movie_id = t.id
),
CompanyTitles AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
ActorsAndTitles AS (
    SELECT 
        a.person_id,
        at.title,
        at.production_year,
        ct.companies
    FROM 
        ActorTitles at
    JOIN 
        CompanyTitles ct ON at.title = ct.title
)

SELECT 
    a.person_id,
    a.title,
    a.production_year,
    a.companies,
    CASE 
        WHEN a.companies IS NULL THEN 'No Company Associated'
        ELSE a.companies
    END AS companies_status
FROM 
    ActorsAndTitles a
WHERE 
    a.actor_title_rank = 1 
    AND a.production_year > 1990
ORDER BY 
    a.production_year DESC, 
    a.title;
