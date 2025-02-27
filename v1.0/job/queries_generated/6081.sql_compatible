
WITH movie_details AS (
    SELECT t.id AS movie_id, t.title, t.production_year, ct.kind AS company_type, STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM aka_title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id, t.title, t.production_year, ct.kind
),
actor_details AS (
    SELECT c.movie_id, a.name AS actor_name, r.role
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
)
SELECT md.movie_id, md.title, md.production_year, md.company_type, md.keywords, STRING_AGG(ad.actor_name || ' (' || ad.role || ')', ', ') AS actors
FROM movie_details md
LEFT JOIN actor_details ad ON md.movie_id = ad.movie_id
GROUP BY md.movie_id, md.title, md.production_year, md.company_type, md.keywords
ORDER BY md.production_year DESC, md.title;
