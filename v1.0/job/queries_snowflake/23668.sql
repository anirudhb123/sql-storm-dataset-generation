
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT m.company_id) AS num_production_companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id AND m.note IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.num_production_companies,
        rt.rn,
        CASE 
            WHEN rt.rn = 1 AND rt.num_production_companies > 0 THEN 'Latest Production'
            ELSE 'Other'
        END AS title_status
    FROM 
        RankedTitles rt
    WHERE 
        rt.num_production_companies > 3 
        OR (rt.production_year IS NULL)
),
PersonRoleCounts AS (
    SELECT 
        c.role_id,
        COUNT(DISTINCT c.person_id) AS role_count
    FROM 
        cast_info c
    GROUP BY 
        c.role_id
),
ComplexJoin AS (
    SELECT 
        ft.title,
        ft.title_status,
        pr.role_count,
        COALESCE(ft.num_production_companies, 0) AS comp_count
    FROM 
        FilteredTitles ft
    LEFT JOIN 
        PersonRoleCounts pr ON ft.title_id = pr.role_id
)
SELECT 
    cj.title,
    cj.title_status,
    cj.role_count,
    cj.comp_count,
    CASE 
        WHEN cj.role_count IS NULL THEN 'No roles found'
        ELSE 'Roles exist'
    END AS role_info,
    CASE 
        WHEN cj.comp_count = 0 THEN 'No companies involved'
        ELSE 'Companies involved: ' || CAST(cj.comp_count AS STRING)
    END AS company_info,
    COALESCE(NULLIF(cj.title_status, 'Latest Production'), 'Older or no production') AS status_description
FROM 
    ComplexJoin cj
ORDER BY 
    cj.title_status DESC, 
    cj.title;
