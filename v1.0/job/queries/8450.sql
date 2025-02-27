SELECT 
    p.id AS person_id,
    p.name AS person_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    m.info AS movie_info
FROM 
    name p
JOIN 
    cast_info ci ON p.id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    p.gender = 'F' 
    AND t.production_year BETWEEN 2000 AND 2020 
    AND k.keyword LIKE '%drama%'
ORDER BY 
    t.production_year DESC, 
    p.name;
