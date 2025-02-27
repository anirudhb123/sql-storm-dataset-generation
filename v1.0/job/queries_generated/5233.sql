WITH movie_years AS (
    SELECT production_year, COUNT(*) AS movie_count
    FROM aka_title
    GROUP BY production_year
),
actor_roles AS (
    SELECT a.name AS actor_name, r.role AS role_type, COUNT(*) AS role_count
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY a.name, r.role
),
company_info AS (
    SELECT c.name AS company_name, ct.kind AS company_type, COUNT(mc.id) AS movies_produced
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY c.name, ct.kind
)
SELECT my.production_year, my.movie_count, ar.actor_name, ar.role_type, ar.role_count, ci.company_name, ci.company_type, ci.movies_produced
FROM movie_years my
JOIN actor_roles ar ON my.movie_count > 5
JOIN company_info ci ON ci.movies_produced >= 3
ORDER BY my.production_year DESC, ar.role_count DESC, ci.movies_produced DESC;
