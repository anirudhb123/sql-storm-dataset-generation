SELECT a.name AS actor_name, 
       t.title AS movie_title, 
       c.nr_order AS cast_order, 
       comp.name AS company_name, 
       ci.kind AS company_type, 
       COUNT(mi.id) AS info_count, 
       STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN title t ON c.movie_id = t.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name comp ON mc.company_id = comp.id
JOIN company_type ci ON mc.company_type_id = ci.id
LEFT JOIN movie_info mi ON t.id = mi.movie_id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
WHERE a.name IS NOT NULL 
  AND t.production_year BETWEEN 2000 AND 2023
GROUP BY a.name, t.title, c.nr_order, comp.name, ci.kind
ORDER BY a.name, t.title;
