WITH actor_movies AS (
    SELECT c.movie_id, a.name AS actor_name
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.nr_order = 1
),
movie_details AS (
    SELECT t.title, t.production_year, kt.kind AS movie_kind
    FROM aka_title t
    JOIN kind_type kt ON t.kind_id = kt.id
),
company_details AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
info_details AS (
    SELECT mi.movie_id, mi.info_type_id, mi.info
    FROM movie_info mi
    WHERE mi.note IS NOT NULL
)
SELECT am.actor_name, md.title, md.production_year, md.movie_kind, cd.company_name, cd.company_type, id.info
FROM actor_movies am
JOIN movie_details md ON am.movie_id = md.movie_id
JOIN company_details cd ON am.movie_id = cd.movie_id
LEFT JOIN info_details id ON am.movie_id = id.movie_id
ORDER BY md.production_year DESC, am.actor_name;
