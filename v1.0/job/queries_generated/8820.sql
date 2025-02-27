WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorTitles AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        rt.title,
        rt.production_year
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN RankedTitles rt ON ci.movie_id = rt.title_id
),
CompanyTitles AS (
    SELECT 
        c.id AS company_id,
        c.name AS company_name,
        t.title,
        t.production_year
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    JOIN title t ON mc.movie_id = t.id
)
SELECT 
    at.name AS actor_name,
    COUNT(DISTINCT at.title) AS total_titles,
    ct.company_name,
    ct.production_year,
    STRING_AGG(DISTINCT at.title, ', ') AS titles
FROM ActorTitles at
JOIN CompanyTitles ct ON at.production_year = ct.production_year
GROUP BY 
    at.name, ct.company_name, ct.production_year
HAVING COUNT(DISTINCT at.title) > 5
ORDER BY 
    total_titles DESC, ct.company_name;
