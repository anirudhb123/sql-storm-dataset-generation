SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    m.name AS company_name, 
    k.keyword AS movie_keyword, 
    ci.note AS cast_note 
FROM 
    cast_info ci 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name m ON mc.company_id = m.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year BETWEEN 1990 AND 2000 
    AND ci.nr_order < 3 
ORDER BY 
    t.production_year DESC, 
    a.name;
