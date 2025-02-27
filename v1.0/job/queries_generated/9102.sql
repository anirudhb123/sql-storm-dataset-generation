SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS cast_note,
    c.nr_order AS cast_order,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    mt.kind AS movie_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    kind_type mt ON t.kind_id = mt.id
WHERE 
    a.name LIKE 'J%' 
    AND t.production_year > 2000
    AND co.country_code IN ('USA', 'UK')
ORDER BY 
    t.production_year DESC, 
    a.name ASC
LIMIT 100;
