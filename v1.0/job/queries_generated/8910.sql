SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    mc.note AS company_note
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND k.keyword ILIKE '%action%'
ORDER BY 
    t.production_year DESC, a.name;
