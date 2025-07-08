SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    c.note AS cast_note,
    tp.kind AS production_type,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    kind_type tp ON t.kind_id = tp.id
JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON c.movie_id = mi.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000
    AND co.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name
LIMIT 100;
