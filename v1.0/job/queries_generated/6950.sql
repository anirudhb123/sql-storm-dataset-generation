WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year > 2000
),
ActorStats AS (
    SELECT 
        a.id AS actor_id, 
        a.name, 
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),
CompanyStats AS (
    SELECT 
        c.id AS company_id, 
        c.name, 
        COUNT(mc.movie_id) AS movie_count
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    GROUP BY 
        c.id, c.name
)
SELECT 
    rt.title, 
    rt.production_year, 
    as.name AS actor_name, 
    as.movie_count AS actor_movie_count, 
    cs.name AS company_name, 
    cs.movie_count AS company_movie_count
FROM 
    RankedTitles rt
JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
JOIN 
    aka_name as ON ci.person_id = as.person_id
JOIN 
    movie_companies mc ON rt.title_id = mc.movie_id
JOIN 
    company_name cs ON mc.company_id = cs.id
WHERE 
    rt.year_rank <= 5 
ORDER BY 
    rt.production_year DESC, 
    as.movie_count DESC, 
    cs.movie_count DESC;
