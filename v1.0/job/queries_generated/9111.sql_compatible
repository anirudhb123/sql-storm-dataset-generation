
WITH movie_details AS (
    SELECT t.id AS movie_id, t.title, t.production_year, STRING_AGG(DISTINCT k.keyword, ',') AS keywords
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id, t.title, t.production_year
),
cast_details AS (
    SELECT c.movie_id, STRING_AGG(DISTINCT a.name, ',') AS actors, COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
company_details AS (
    SELECT mc.movie_id, STRING_AGG(DISTINCT cn.name, ',') AS companies, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, ct.kind
)
SELECT md.movie_id, md.title, md.production_year, md.keywords, cd.actors, cd.actor_count, co.companies, co.company_type
FROM movie_details md
LEFT JOIN cast_details cd ON md.movie_id = cd.movie_id
LEFT JOIN company_details co ON md.movie_id = co.movie_id
WHERE md.production_year >= 2000
ORDER BY md.production_year DESC, md.title ASC;
