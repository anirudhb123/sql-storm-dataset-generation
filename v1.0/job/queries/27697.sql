
WITH MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        m.name AS company_name,
        ci.role_id,
        a.name AS actor_name,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name m ON mc.company_id = m.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    GROUP BY t.title, t.production_year, m.name, ci.role_id, a.name
),

RoleDetails AS (
    SELECT 
        md.actor_name, 
        COUNT(DISTINCT md.role_id) AS role_count,
        COUNT(DISTINCT md.title) AS movie_count,
        STRING_AGG(DISTINCT md.company_name, ', ') AS companies
    FROM MovieDetails md
    JOIN role_type rt ON md.role_id = rt.id
    GROUP BY md.actor_name
)

SELECT 
    rd.actor_name, 
    rd.role_count, 
    rd.movie_count, 
    rd.companies
FROM RoleDetails rd
ORDER BY rd.movie_count DESC, rd.role_count DESC
LIMIT 10;
