SELECT 
    a.name AS actor_name, 
    m.title AS movie_title, 
    k.keyword AS movie_keyword,
    c.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    title m ON at.movie_id = m.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON m.id = mi.movie_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    a.name;
