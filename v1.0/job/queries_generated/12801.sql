SELECT 
    k.keyword,
    t.title,
    n.name AS person_name,
    c.kind AS company_type,
    m.info AS movie_info
FROM 
    movie_keyword mk
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    aka_title t ON mk.movie_id = t.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name n ON ci.person_id = n.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    k.keyword;
