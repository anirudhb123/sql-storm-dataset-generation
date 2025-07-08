
WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS RankYear
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorTitleInfo AS (
    SELECT 
        a.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT c.role_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title at ON c.movie_id = at.movie_id
    GROUP BY 
        a.name, at.title, at.production_year
),
CompanyAggregate AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    a.actor_name,
    a.movie_title,
    a.production_year,
    COALESCE(ca.company_names, ARRAY_CONSTRUCT()) AS company_names,
    COALESCE(ca.num_companies, 0) AS num_companies,
    rt.RankYear
FROM 
    ActorTitleInfo a
LEFT JOIN 
    CompanyAggregate ca ON a.movie_title = ca.movie_id
JOIN 
    RankedTitles rt ON a.production_year = rt.production_year
WHERE 
    a.role_count > 1 
    AND rt.RankYear <= 5
ORDER BY 
    a.production_year DESC, a.actor_name;
