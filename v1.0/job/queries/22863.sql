
WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        c.role AS role_name,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type c ON ci.role_id = c.id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    rt.title,
    rt.production_year,
    MAX(ac.actor_name) AS lead_actor,
    COUNT(DISTINCT ac.role_name) AS distinct_roles,
    STRING_AGG(DISTINCT ac.role_name, ', ') AS roles_list,
    CASE
        WHEN rt.production_year > 2000 THEN 'Modern Era'
        WHEN rt.production_year BETWEEN 1990 AND 2000 THEN '90s Classic'
        ELSE 'Oldies'
    END AS era_category
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorCast ac ON rt.title_id = ac.movie_id
GROUP BY 
    rt.title, rt.production_year, rt.title_rank
HAVING 
    COUNT(ac.actor_name) > 2
ORDER BY 
    rt.production_year DESC, title_rank;
