WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title AS title_name,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.name) AS rank
    FROM 
        aka_name a
    JOIN 
        aka_title at ON a.id = at.id
    JOIN 
        title t ON at.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
CastedTitles AS (
    SELECT 
        rt.aka_id,
        rt.aka_name,
        rt.title_id,
        rt.title_name,
        rt.production_year,
        c.person_role_id,
        r.role AS role_name
    FROM 
        RankedTitles rt
    JOIN 
        cast_info c ON rt.title_id = c.movie_id
    JOIN 
        role_type r ON c.person_role_id = r.id
),
FilteredTitles AS (
    SELECT 
        ct.aka_id,
        ct.aka_name,
        ct.title_name,
        ct.production_year,
        COUNT(ct.role_name) AS role_count
    FROM 
        CastedTitles ct
    GROUP BY 
        ct.aka_id, ct.aka_name, ct.title_name, ct.production_year
    HAVING 
        COUNT(ct.role_name) > 2
)
SELECT 
    ft.aka_name,
    ft.title_name,
    ft.production_year,
    ft.role_count
FROM 
    FilteredTitles ft
ORDER BY 
    ft.production_year DESC, ft.role_count DESC;
