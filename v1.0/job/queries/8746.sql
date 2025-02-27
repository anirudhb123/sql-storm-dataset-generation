
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    ct.kind AS company_type,
    k.keyword AS keyword,
    m.info AS movie_info
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
LEFT JOIN 
    movie_info m ON t.id = m.movie_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND ct.kind = 'Production Company' 
ORDER BY 
    t.production_year DESC, 
    a.name, 
    t.title;
