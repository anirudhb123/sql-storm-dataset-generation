WITH movie_details AS (
    SELECT t.title, t.production_year, k.keyword 
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
), company_details AS (
    SELECT cn.name AS company_name, ct.kind AS company_type, mc.movie_id 
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
), cast_details AS (
    SELECT ci.movie_id, an.name AS actor_name, rt.role 
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    JOIN role_type rt ON ci.role_id = rt.id
), complete_details AS (
    SELECT md.title, md.production_year, cd.company_name, cd.company_type, 
           cd.movie_id, ca.actor_name, ca.role 
    FROM movie_details md
    JOIN company_details cd ON md.production_year = cd.company_name
    JOIN cast_details ca ON md.movie_id = ca.movie_id
)
SELECT title, production_year, company_name, company_type, actor_name, role 
FROM complete_details
ORDER BY production_year DESC, title ASC;
