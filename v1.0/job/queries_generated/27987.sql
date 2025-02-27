WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.person_id) AS cast_count,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_role,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT kc.person_id) DESC) AS rank_with_cast,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title) AS rank_total
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name kc ON ci.person_id = kc.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),

FilteredTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.cast_count,
        rt.has_role,
        rt.rank_with_cast,
        rt.rank_total
    FROM 
        RankedTitles rt
    WHERE 
        rt.cast_count > 5 AND rt.production_year BETWEEN 1990 AND 2020
),

TopTitles AS (
    SELECT 
        ft.title,
        ft.production_year,
        ft.cast_count,
        ft.has_role
    FROM 
        FilteredTitles ft
    WHERE
        ft.rank_with_cast <= 10
)

SELECT 
    tt.title,
    tt.production_year,
    tt.cast_count,
    tt.has_role,
    GROUP_CONCAT(DISTINCT CONCAT(ka.name, ' (', ka.md5sum, ')') ORDER BY ka.name) AS cast_members
FROM 
    TopTitles tt
LEFT JOIN 
    cast_info ci ON ci.movie_id = tt.title_id
LEFT JOIN 
    aka_name ka ON ka.person_id = ci.person_id
GROUP BY 
    tt.title, tt.production_year, tt.cast_count, tt.has_role
ORDER BY 
    tt.production_year DESC, tt.title;
