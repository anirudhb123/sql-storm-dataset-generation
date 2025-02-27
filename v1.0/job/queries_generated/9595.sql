SELECT p.name AS actor_name, 
       t.title AS movie_title, 
       c.role_id AS role_id, 
       ct.kind AS company_type, 
       COUNT(mk.keyword) AS keyword_count
FROM aka_name p
JOIN cast_info c ON p.person_id = c.person_id
JOIN title t ON c.movie_id = t.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
WHERE p.name ILIKE '%Smith%'
AND t.production_year BETWEEN 2000 AND 2023
GROUP BY p.name, t.title, c.role_id, ct.kind
ORDER BY keyword_count DESC, actor_name ASC, movie_title ASC;
