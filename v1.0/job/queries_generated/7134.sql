SELECT DISTINCT a.name AS actor_name, 
                t.title AS movie_title, 
                t.production_year, 
                c.kind AS cast_type, 
                m.name AS company_name, 
                k.keyword AS movie_keyword
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name m ON mc.company_id = m.id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN kind_type ct ON t.kind_id = ct.id
WHERE a.name IS NOT NULL
  AND t.production_year BETWEEN 2000 AND 2023
  AND m.country_code = 'USA'
ORDER BY t.production_year DESC, actor_name ASC
LIMIT 100;
