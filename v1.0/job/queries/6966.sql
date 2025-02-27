
WITH filtered_movies AS (
    SELECT t.title, t.production_year, t.id AS movie_id
    FROM title t
    JOIN aka_title at ON t.id = at.movie_id
    WHERE at.production_year >= 2000 AND at.kind_id IN (1, 2)
),
cast_and_crew AS (
    SELECT ak.name AS actor_name, c.role_id, mc.movie_id
    FROM cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    JOIN movie_companies mc ON c.movie_id = mc.movie_id
    JOIN company_name cm ON mc.company_id = cm.id
    WHERE ak.name IS NOT NULL
),
movie_keywords AS (
    SELECT mk.movie_id, k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
)
SELECT fm.title, fm.production_year, c.actor_name, c.role_id, ck.keyword
FROM filtered_movies fm
JOIN cast_and_crew c ON fm.movie_id = c.movie_id
JOIN movie_keywords ck ON fm.movie_id = ck.movie_id
WHERE ck.keyword LIKE '%action%'
ORDER BY fm.production_year DESC, fm.title ASC;
