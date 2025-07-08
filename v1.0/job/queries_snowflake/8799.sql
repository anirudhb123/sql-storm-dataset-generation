SELECT a.name AS actor_name, t.title AS movie_title, c.kind AS cast_type, ci.note AS cast_note, COUNT(mk.keyword_id) AS keyword_count
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN aka_title t ON ci.movie_id = t.movie_id
JOIN comp_cast_type c ON ci.person_role_id = c.id
JOIN movie_keyword mk ON t.id = mk.movie_id
WHERE t.production_year >= 2000
AND c.kind IN ('Cast', 'Crew')
GROUP BY a.name, t.title, c.kind, ci.note
HAVING COUNT(mk.keyword_id) > 3
ORDER BY keyword_count DESC, a.name ASC, t.title ASC
LIMIT 50;
