
WITH MovieInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        STRING_AGG(DISTINCT c.name, ',') AS companies
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    GROUP BY t.id, t.title, t.production_year
),
PersonRole AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS total_roles
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id, r.role
),
FinalBenchmark AS (
    SELECT 
        mi.title,
        mi.production_year,
        mi.keywords,
        pr.role,
        pr.total_roles
    FROM MovieInfo mi
    LEFT JOIN PersonRole pr ON mi.title_id = pr.movie_id
    WHERE mi.production_year >= 2000
    ORDER BY mi.production_year DESC, pr.total_roles DESC
)
SELECT 
    title,
    production_year,
    keywords,
    role,
    total_roles
FROM FinalBenchmark
WHERE role IS NOT NULL
LIMIT 100;
