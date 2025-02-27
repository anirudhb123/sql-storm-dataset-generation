SELECT 
    t.title AS movie_title,
    an.name AS actor_name,
    ct.kind AS cast_type,
    mk.keyword AS movie_keyword,
    ci.note AS cast_note
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    an.name;
