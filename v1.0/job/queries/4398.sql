WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(MIN(mi.info), 'No Info') AS movie_info,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM aka_title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    GROUP BY m.id, m.title
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(DISTINCT ci.person_id) AS num_cast_members
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id, rt.role
)
SELECT 
    rt.title AS ranked_title,
    rt.production_year,
    md.movie_title,
    md.movie_info,
    cr.role,
    cr.num_cast_members,
    md.num_companies,
    CASE 
        WHEN md.num_companies > 0 THEN 'Has Companies'
        ELSE 'No Companies'
    END AS company_status
FROM RankedTitles rt
JOIN MovieDetails md ON rt.rank = 1 AND md.movie_title = rt.title
LEFT JOIN CastRoles cr ON md.movie_id = cr.movie_id
WHERE rt.production_year > 2000
ORDER BY rt.production_year DESC, md.num_companies DESC;
