SELECT a.name AS actor_name, 
       t.title AS movie_title, 
       c.kind AS company_type, 
       k.keyword AS movie_keyword, 
       COUNT(DISTINCT m.id) AS movie_count 
FROM aka_name a 
JOIN cast_info ci ON a.person_id = ci.person_id 
JOIN title t ON ci.movie_id = t.id 
JOIN movie_companies mc ON t.id = mc.movie_id 
JOIN company_type c ON mc.company_type_id = c.id 
JOIN movie_keyword mk ON t.id = mk.movie_id 
JOIN keyword k ON mk.keyword_id = k.id 
JOIN complete_cast cc ON t.id = cc.movie_id 
WHERE a.name IS NOT NULL 
  AND c.kind IS NOT NULL 
  AND k.keyword IS NOT NULL 
GROUP BY a.name, t.title, c.kind, k.keyword 
ORDER BY movie_count DESC 
LIMIT 10;
