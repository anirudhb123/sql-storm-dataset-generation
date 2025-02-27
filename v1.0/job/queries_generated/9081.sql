SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    p.gender AS actor_gender,
    mi.info AS movie_info,
    k.keyword AS movie_keyword,
    cnt.name AS company_name,
    ci.note AS cast_note
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cnt ON mc.company_id = cnt.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year > 2000
    AND a.name IS NOT NULL
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    a.name;
