WITH RecursiveMovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT co.name) AS companies
    FROM title t
    JOIN aka_title ak ON t.id = ak.movie_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name co ON mc.company_id = co.id
    GROUP BY t.id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        r.role AS role,
        COUNT(ci.person_id) AS role_count
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.movie_id, r.role
),
FinalBenchmark AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(c.role, 'No Role') AS role,
        c.role_count,
        m.aka_names,
        m.companies
    FROM RecursiveMovieInfo m
    LEFT JOIN CastRoles c ON m.movie_id = c.movie_id
)
SELECT 
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.role,
    fb.role_count,
    fb.aka_names,
    fb.companies
FROM FinalBenchmark fb
WHERE fb.production_year >= 2000
ORDER BY fb.production_year DESC, fb.title;
