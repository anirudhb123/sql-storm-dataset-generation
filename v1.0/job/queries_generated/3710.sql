WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS role_count,
        COUNT(DISTINCT ci.person_id) AS total_cast_members
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
FilteredTitles AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.total_cast_members
    FROM 
        RankedTitles rt
    WHERE 
        rt.role_count = 1
)
SELECT 
    ft.title,
    ft.production_year,
    COALESCE(SUM(CASE WHEN ci.note LIKE '%lead%' THEN 1 ELSE 0 END), 0) AS lead_roles_count,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names
FROM 
    FilteredTitles ft
LEFT JOIN 
    cast_info ci ON ft.title = (SELECT at.title FROM aka_title at WHERE at.movie_id = ci.movie_id)
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
GROUP BY 
    ft.title, ft.production_year
HAVING 
    total_cast_members > 0
ORDER BY 
    ft.production_year DESC, lead_roles_count DESC
LIMIT 50;
