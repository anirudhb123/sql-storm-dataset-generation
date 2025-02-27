WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        c.movie_id, 
        r.role, 
        COUNT(c.person_id) AS role_count
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id, r.role
),
MovieCompanies AS (
    SELECT 
        mc.movie_id, 
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
TitleWithRoles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        cr.role,
        cr.role_count,
        tc.company_names
    FROM RankedTitles rt
    LEFT JOIN CastRoles cr ON rt.title_id = cr.movie_id
    LEFT JOIN MovieCompanies tc ON rt.title_id = tc.movie_id
)
SELECT 
    twr.title, 
    twr.production_year, 
    twr.role, 
    COALESCE(twr.role_count, 0) AS role_count,
    COALESCE(twr.company_names, 'No Companies') AS company_names
FROM TitleWithRoles twr
WHERE twr.title_rank <= 5
ORDER BY twr.production_year DESC, twr.role_count DESC, twr.title;
