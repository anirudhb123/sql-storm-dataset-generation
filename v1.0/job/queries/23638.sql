WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRankedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.year_rank <= 3
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        p.name AS actor_name,
        rt.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
)
SELECT 
    tt.title,
    tt.production_year,
    COUNT(DISTINCT ciw.actor_name) AS actor_count,
    STRING_AGG(DISTINCT ciw.actor_name, ', ') AS actor_list,
    MAX(CASE WHEN ciw.role_name LIKE '%lead%' THEN ciw.actor_name END) AS lead_actor,
    SUM(CASE WHEN ciw.role_name IS NOT NULL THEN 1 ELSE 0 END) AS roles_assigned
FROM 
    TopRankedTitles tt
LEFT JOIN 
    CastInfoWithRoles ciw ON tt.title_id = ciw.movie_id
GROUP BY 
    tt.title, 
    tt.production_year
HAVING 
    COUNT(ciw.actor_name) > 1
ORDER BY 
    tt.production_year DESC,
    tt.title ASC;