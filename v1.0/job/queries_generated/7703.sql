SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.gender AS actor_gender,
    c.kind AS cast_type,
    comp.name AS company_name,
    m.production_year,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
JOIN 
    name p ON ci.person_id = p.imdb_id
WHERE 
    t.production_year > 2000
    AND p.gender = 'F'
    AND r.role = 'actor'
ORDER BY 
    m.production_year DESC, 
    a.name;
