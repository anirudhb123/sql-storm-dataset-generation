WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv_series'))
),
CastWithRole AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        r.role AS role_name,
        COALESCE(a.name, 'Unknown') AS actor_name
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT c.name) AS companies
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
FilteredTitles AS (
    SELECT 
        rt.*,
        COALESCE(m.companies, 'No Companies') AS companies
    FROM 
        RankedTitles rt
    LEFT JOIN 
        MovieCompanies m ON rt.title_id = m.movie_id
)
SELECT 
    ft.title,
    ft.production_year,
    ft.rank_per_year,
    cw.actor_name,
    cw.role_name,
    COUNT(DISTINCT cw.person_id) FILTER (WHERE cw.role_name IS NOT NULL) AS actor_count,
    CASE 
        WHEN ft.rank_per_year = 1 THEN 'Top Title'
        WHEN ft.companies = 'No Companies' THEN 'Independent'
        ELSE 'Standard'
    END AS title_category
FROM 
    FilteredTitles ft
LEFT JOIN 
    CastWithRole cw ON ft.title_id = cw.movie_id
WHERE 
    ft.production_year BETWEEN 2000 AND 2020
    AND ft.rank_per_year <= 5
GROUP BY 
    ft.title, ft.production_year, ft.rank_per_year, cw.actor_name, cw.role_name
ORDER BY 
    ft.production_year DESC, ft.rank_per_year ASC, actor_count DESC;
