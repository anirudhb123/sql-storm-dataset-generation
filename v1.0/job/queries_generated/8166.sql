SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.note AS cast_note,
    k.keyword AS movie_keyword,
    c2.kind AS company_type,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c2 ON mc.company_type_id = c2.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000 
    AND k.keyword ILIKE '%action%' 
    AND a.name NOT LIKE '%stunt%'
ORDER BY 
    t.production_year DESC, 
    a.name;
