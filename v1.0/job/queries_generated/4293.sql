WITH RankedTitles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM aka_title a
    WHERE a.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.person_id,
        r.role,
        COUNT(*) AS role_count
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.person_id, r.role
),
TopActors AS (
    SELECT 
        ar.person_id,
        SUM(ar.role_count) AS total_roles
    FROM ActorRoles ar
    GROUP BY ar.person_id
    ORDER BY total_roles DESC
    LIMIT 10
),
MoviesWithCompanyDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        c.name AS company_name,
        ct.kind AS company_type
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(tac.total_roles, 0) AS actor_role_count,
    mwcd.company_name,
    mwcd.company_type
FROM RankedTitles rt
LEFT JOIN MoviesWithCompanyDetails mwcd ON rt.title_id = mwcd.movie_id
LEFT JOIN TopActors tac ON mwcd.movie_id IN (
    SELECT DISTINCT movie_id FROM cast_info WHERE person_id = tac.person_id
)
WHERE rt.title_rank <= 5 AND rt.production_year >= 2000
ORDER BY rt.production_year DESC, rt.title;
