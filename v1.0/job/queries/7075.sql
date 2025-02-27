SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    cm.name AS company_name,
    mi.info AS movie_info,
    ti.kind AS title_kind
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cm ON mc.company_id = cm.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    kind_type ti ON t.kind_id = ti.id
WHERE 
    a.name LIKE '%Smith%'
    AND t.production_year > 2000
    AND c.kind IN (SELECT kind FROM comp_cast_type WHERE kind LIKE '%Actor%')
ORDER BY 
    t.production_year DESC, a.name;
