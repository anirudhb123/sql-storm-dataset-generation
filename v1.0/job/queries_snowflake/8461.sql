SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_kind,
    m.info AS movie_data_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    p.info AS person_data_info 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    kind_type c ON t.kind_id = c.id 
JOIN 
    movie_info m ON t.id = m.movie_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND k.keyword LIKE '%action%' 
    AND co.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, a.name ASC;
