WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.person_id,
        a.name,
        r.role,
        COUNT(ci.movie_id) AS movie_count
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY a.person_id, a.name, r.role
    HAVING COUNT(ci.movie_id) > 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    ar.name AS actor_name,
    ar.role AS actor_role,
    ar.movie_count,
    mc.company_name,
    mc.company_type
FROM RankedMovies m
LEFT JOIN ActorRoles ar ON m.movie_id = ar.person_id
LEFT JOIN MovieCompanies mc ON m.movie_id = mc.movie_id
WHERE m.year_rank <= 10
  AND (mc.company_name IS NOT NULL OR mc.company_type IS NULL)
ORDER BY m.production_year DESC, ar.movie_count DESC
LIMIT 100;
